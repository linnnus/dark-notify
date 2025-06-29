local M = {}

local function on_exit(code, signal)
	error(string.format("dark-notify background process unexpectedly exited with code %d and signal %d", code, signal))
end

local function on_output(err, data)
	if err then
		error("error reading from stdout of dark-notify background process: " .. err)
	elseif data then
		M.change_theme(vim.trim(data))
	else
		-- stream closed, but error()ing here would swallow the
		-- (likely) companion error message from on_exit().
		error("dark-notify background process unexpectantly closed stdout")
	end
end

function M.setup()
	local stdout = vim.uv.new_pipe()
	local process, pid = vim.uv.spawn("dark-notify", {
		stdio = {nil, stdout, nil}
	}, on_exit)
	stdout:read_start(on_output)
end

function M.change_theme(theme)
	if theme == "light" then
		vim.schedule(function() vim.cmd("set background=light") end)
	elseif theme == "dark" then
		vim.schedule(function() vim.cmd("set background=dark") end)
	else
		error("Unknown theme '" .. theme "'. Expected: 'light' or 'dark'")
	end
end

return M
