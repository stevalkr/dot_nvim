-- Headless Neovim tests against a fake owner socket.
-- Run with: nvim --clean --headless -l tests/test_nvim.lua
local root_dir = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(debug.getinfo(1, "S").source:sub(2))))
vim.opt.rtp:prepend(root_dir)

local workspace = vim.fn.tempname()
vim.fn.mkdir(vim.fs.joinpath(workspace, "src"), "p")
vim.fn.writefile({ "one", "two", "three", "four", "five" }, vim.fs.joinpath(workspace, "src", "a.txt"))
vim.cmd.cd(workspace)
-- Unix socket paths are short; the temp workspace may be too deep on macOS.
local sock = vim.fs.joinpath("/tmp", "crn" .. vim.uv.os_getpid() .. ".sock")
os.remove(sock)

local failures = 0
local function check(name, condition, detail)
	if condition then
		io.stdout:write("ok   " .. name .. "\n")
	else
		failures = failures + 1
		io.stdout:write("FAIL " .. name .. (detail and (": " .. vim.inspect(detail)) or "") .. "\n")
	end
end

-- Fake owner: records messages from Neovim and can send messages back.
local owner = { received = {}, conn = nil }
function owner.start()
	owner.server = assert(vim.uv.new_pipe(false))
	assert(owner.server:bind(sock))
	owner.server:listen(4, function()
		local conn = assert(vim.uv.new_pipe(false))
		owner.server:accept(conn)
		owner.conn = conn
		local buffer = ""
		conn:read_start(function(_, chunk)
			if not chunk then
				return
			end
			buffer = buffer .. chunk
			for line in buffer:gmatch("([^\n]*)\n") do
				table.insert(owner.received, vim.json.decode(line))
			end
			buffer = buffer:match("[^\n]*$")
		end)
	end)
end
function owner.stop()
	if owner.conn then
		owner.conn:close()
		owner.conn = nil
	end
	owner.server:close()
	os.remove(sock)
end
function owner.send(message)
	owner.conn:write(vim.json.encode(message) .. "\n")
end
function owner.find(predicate)
	for _, message in ipairs(owner.received) do
		if predicate(message) then
			return message
		end
	end
end
local function wait(predicate)
	return vim.wait(3000, predicate, 10)
end

local client = require("claude-review.client")
local review = require("claude-review")
local store = require("claude-review.store")
local ui = require("claude-review.ui")

review.setup({ socket = sock })
vim.cmd.edit("src/a.txt")
local buf = vim.api.nvim_get_current_buf()

-- A comment sent while no owner listens stays `sent` and is delivered on connect.
local comment = store.add("src/a.txt", 2, 3, "Explain this")
ui.render(buf)
check("draft has an extmark", comment._mark ~= nil)
vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "new first line" })
ui.sync(buf)
check("extmark follows edits", comment.start_line == 3 and comment.end_line == 4, comment)

vim.api.nvim_win_set_cursor(0, { 3, 0 })
review.send()
check("state sent without owner", comment.state == "sent" and not comment.acked)

owner.start()
check(
	"resent after connect",
	wait(function()
		return owner.find(function(m)
			return m.type == "comment" and m.id == comment.id
		end) ~= nil
	end)
)
local hello = owner.find(function(m)
	return m.type == "hello"
end)
check("hello as nvim", hello and hello.role == "nvim", hello)
local sent = owner.find(function(m)
	return m.type == "comment"
end)
check("comment payload", sent and sent.path == "src/a.txt" and sent.start_line == 3 and sent.end_line == 4, sent)

owner.send({ type = "ack", id = comment.id })
check(
	"delivered after ack",
	wait(function()
		return comment.state == "delivered"
	end),
	comment.state
)

owner.send({
	type = "reply",
	comment_id = comment.id,
	text = "It counts.",
	resolve = false,
})
check(
	"replied",
	wait(function()
		return comment.state == "replied"
	end),
	comment
)
check("reply in thread", comment.thread[1] and comment.thread[1].from == "claude")

-- Follow-up, then a reply addressed to the follow-up message id.
local entry = store.follow_up(comment, "And why?")
client.send(store.payload(comment, entry))
check(
	"follow-up payload",
	wait(function()
		return owner.find(function(m)
			return m.id == entry.id and m.thread_id == comment.id
		end) ~= nil
	end)
)
owner.send({ type = "ack", id = entry.id })
owner.send({
	type = "reply",
	comment_id = entry.id,
	text = "Done.",
	resolve = true,
})
check(
	"resolved via follow-up id",
	wait(function()
		return comment.state == "resolved"
	end),
	comment
)
check("follow-up no longer pending", not entry.pending)

owner.send({
	type = "quickfix",
	title = "Claude changes",
	mode = "replace",
	items = { { path = "src/a.txt", lnum = 2, text = "changed" } },
})
check(
	"quickfix set",
	wait(function()
		return vim.fn.getqflist({ title = 0 }).title == "Claude changes"
	end)
)
local items = vim.fn.getqflist()
check(
	"quickfix item",
	#items == 1
		and items[1].lnum == 2
		and vim.uv.fs_realpath(vim.api.nvim_buf_get_name(items[1].bufnr))
			== vim.uv.fs_realpath(vim.fs.joinpath(workspace, "src", "a.txt")),
	items
)

owner.send({ type = "comments_req", req_id = "r1" })
check(
	"comments response",
	wait(function()
		local response = owner.find(function(m)
			return m.type == "comments" and m.req_id == "r1"
		end)
		return response and #response.items == 1 and response.items[1]._mark == nil
	end)
)

owner.send({ type = "state_req", req_id = "r2" })
check(
	"state response",
	wait(function()
		local response = owner.find(function(m)
			return m.type == "state" and m.req_id == "r2"
		end)
		return response and response.path == "src/a.txt"
	end)
)

-- Persistence: written on save, read back by a fresh load.
vim.cmd.write()
local saved = store.data.comments
store.load(workspace)
check("persisted", #store.data.comments == 1 and store.data.comments[1].state == "resolved")
check("persisted lines", store.data.comments[1].start_line == 3, store.data.comments[1])
store.data.comments = saved

-- Unacked comments are resent after the owner restarts.
local second = store.add("src/a.txt", 1, 1, "Second")
second.state = "sent"
owner.stop()
owner.received = {}
check(
	"disconnected",
	wait(function()
		return not client.connected()
	end)
)
owner.start()
check(
	"resent after reconnect",
	wait(function()
		return owner.find(function(m)
			return m.type == "comment" and m.id == second.id
		end) ~= nil
	end)
)

review.disconnect()
check(
	"bye on disconnect",
	wait(function()
		return owner.find(function(m)
			return m.type == "bye"
		end) ~= nil
	end)
)

owner.stop()
vim.fn.delete(workspace, "rf")
io.stdout:write(failures == 0 and "all passed\n" or (failures .. " failed\n"))
os.exit(failures == 0 and 0 or 1)
