local M = {}

local volt = require("volt")

M.log = function(args)
	if M.logfile then
		M.logfile:write(os.date() .. ": " .. vim.inspect(args) .. "\n")
		M.logfile:flush()
	end
end

M.barlines = function()
	local text_len = 0
	local line = {}
	local count = 0
	local num_of_terms = M.term_count()
	for i, v in pairs(M.terminals) do
		count = count + 1
		if v.buf == M.cur_term.buf then
			hl_color = "exgreen"
		else
			hl_color = "comment"
		end
		name = { v.name .. "[" .. tostring(i) .. "]", hl_color }
		text_len = text_len + #name[1]
		table.insert(line, name)
		if count ~= num_of_terms then
			table.insert(line, { "|", "comment" })
			text_len = text_len + 1
		end
	end
	return { line }
end

M.setup = function(opts)
	if M.is_setup then
		return
	end
	M.is_setup = true
	opts = opts or {}
	if opts.logfile then
		M.logfile = io.open(opts.logfile, "a")
		M.log("Logfile: " .. opts.logfile)
	end
	if opts.toggle_keymap then
		vim.keymap.set(opts.toggle_keymap[1], opts.toggle_keymap[2], M.toggle)
	end
	if opts.new_term_keymap then
		vim.keymap.set(opts.new_term_keymap[1], opts.new_term_keymap[2], M.add_term)
	end
	if opts.next_term_keymap then
		vim.keymap.set(opts.next_term_keymap[1], opts.next_term_keymap[2], M.next_term)
	end
	if opts.prev_term_keymap then
		vim.keymap.set(opts.prev_term_keymap[1], opts.prev_term_keymap[2], M.prev_term)
	end
	opts.size = opts.size or { h = 80, w = 80 }
	opts.size.h = opts.size.h or 80
	opts.size.w = opts.size.w or 80
	M.size = opts.size
	M.terminals = {}
	M.ns = vim.api.nvim_create_namespace("termpop")
	M.augroup = vim.api.nvim_create_augroup("TermPopAu", { clear = true })
	M.barbuf = vim.api.nvim_create_buf(false, true)
	volt.gen_data({
		{
			buf = M.barbuf,
			ns = M.ns,
			layout = {
					{
						lines = M.barlines,
						name = "bar",
					},
			},
		},
	})
	vim.api.nvim_create_autocmd("BufUnload", {
		group = M.augroup,
		callback = function(args)
			M.log({"BufUnload: ", args})
			vim.schedule(function()
				M.delete_term(args.buf)
			end)
		end,
	})

end

M.next_term = function()
	M.log("Next term")
end

M.prev_term = function()
	M.log("Prev term")
end

M.delete_term = function(buf)
	local bordered = true
	local bordered = true
	local h = math.floor(vim.o.lines * (M.size.h / 100))
	local bar_row = math.ceil((vim.o.lines - h) / 2)
	local w = math.floor(vim.o.columns * (M.size.w / 100))
	local bar_col = math.ceil((vim.o.columns - w) / 2)

	local colored_border = {
		{ " ", "exdarkborder" },
		{ "‾", "FloatSpecialBorder" },
		{ " ", "exdarkborder" },
		{ " ", "exdarkborder" },
		{ " ", "exdarkborder" },
		{ " ", "exdarkborder" },
		{ " ", "exdarkborder" },
		{ " ", "exdarkborder" },
	}

	local term_win_opts = {
		row = bar_row + 3,
		col = bar_col,
		width = w,
		height = h - (bordered and 3 or 2),
		relative = "editor",
		style = "minimal",
		border = bordered and "single" or colored_border,
		zindex = 100,
	}

	for i, v in pairs(M.terminals) do
		if v.buf == buf then
			M.log("Deleted terminal: " .. v.name)
			table.remove(M.terminals, i)
			volt.redraw(M.barbuf, "bar")
			if v.buf == M.cur_term.buf then
				M.cur_term = nil
				if M.term_count() > 0 then
					for i,v in pairs(M.terminals) do
						M.cur_term = v
						break
					end
				end
			end
			if M.is_visble then
				if M.term_count() == 0 then
					M.is_visble = nil
					M.log("Hiding")
					vim.api.nvim_win_close(M.barwin, false)
					M.barwin = nil
					if vim.api.nvim_win_is_valid(M.termwin) then
						vim.api.nvim_win_close(M.termwin, false)
					end
					M.termwin = nil
					return
				else
					if vim.api.nvim_win_is_valid(M.termwin) then
						vim.api.nvim_win_close(M.termwin, false)
					end
					M.termwin = vim.api.nvim_open_win(M.cur_term.buf, true, term_win_opts)
					if bordered then
						vim.wo[M.termwin].winhl = "Normal:normal,floatborder:comment"
					else
						vim.wo[M.termwin].winhl = "Normal:exdarkbg,floatBorder:exdarkborder"
					end
				end
			end
			return
		end
	end
end

M.term_count = function()
	local count = 0
	for _ in pairs(M.terminals) do
		count = count + 1
	end
	return count
end

M.term_last = function()
	local count = 0
	for i, v in pairs(M.terminals) do
		count = count + 1
		if count == M.term_count() then
			return i, v
		end
	end
end

M.new_term_buf = function(opts)
	opts = opts or {}
	local term = {
		name = opts.name or "bash",
		buf = vim.api.nvim_create_buf(false, true),
		cmd = opts.cmd or { vim.o.shell },
	}
	return term
end

M.add_term = function(opts)
	local term = M.new_term_buf(opts)
	table.insert(M.terminals, term)
	M.log("Added terminal: " .. term.name)
	M.cur_term = term
	local cur_buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_set_current_buf(term.buf)
	vim.fn.jobstart(term.cmd, { term = true })
	vim.api.nvim_set_current_buf(cur_buf)

	volt.redraw(M.barbuf, "bar")

	if not M.is_visble then
		M.show()
	end
end

M.show = function()
	M.log("Showing")
	M.is_visble = true

	local bordered = true
	local h = math.floor(vim.o.lines * (M.size.h / 100))
	local bar_row = math.ceil((vim.o.lines - h) / 2)
	local w = math.floor(vim.o.columns * (M.size.w / 100))
	local bar_col = math.ceil((vim.o.columns - w) / 2)

	local colored_border = {
		{ " ", "exdarkborder" },
		{ "‾", "FloatSpecialBorder" },
		{ " ", "exdarkborder" },
		{ " ", "exdarkborder" },
		{ " ", "exdarkborder" },
		{ " ", "exdarkborder" },
		{ " ", "exdarkborder" },
		{ " ", "exdarkborder" },
	}

	local bar_win_opts = {
		row = bar_row,
		col = bar_col,
		width = w,
		height = 1,
		relative = "editor",
		style = "minimal",
		border = "single",
		zindex = 100,
	}

	local term_win_opts = {
		row = bar_row + 3,
		col = bar_col,
		width = w,
		height = h - (bordered and 3 or 2),
		relative = "editor",
		style = "minimal",
		border = bordered and "single" or colored_border,
		zindex = 100,
	}

	if M.term_count() == 0 then
		M.log("No terminals, creating one")
		M.add_term()
	end

	M.barwin = vim.api.nvim_open_win(M.barbuf, false, bar_win_opts)
	if bordered then
		vim.wo[M.barwin].winhl = "Normal:normal,floatborder:exred"
	else
		vim.wo[M.barwin].winhl = "Normal:exdarkbg,floatBorder:exdarkborder"
	end

	vim.api.nvim_set_hl(M.ns, "floatBorder", { link = bordered and "comment" or "exblack2border" })
	vim.api.nvim_set_hl(M.ns, "Normal", { link = bordered and "normal" or "exblack2bg" })
	vim.api.nvim_set_option_value("modifiable", true, { buf = M.barbuf })

	M.termwin = vim.api.nvim_open_win(M.cur_term.buf, true, term_win_opts)
	if bordered then
		vim.wo[M.termwin].winhl = "Normal:normal,floatborder:comment"
	else
		vim.wo[M.termwin].winhl = "Normal:exdarkbg,floatBorder:exdarkborder"
	end

	volt.run(M.barbuf, { h = 1, w = bar_win_opts.width })
	volt.redraw(M.barbuf, "bar")
	vim.cmd.startinsert()
end

M.hide = function()
	M.is_visble = nil
	M.log("Hiding")
	vim.api.nvim_win_close(M.barwin, false)
	M.barwin = nil
	vim.api.nvim_win_close(M.termwin, false)
	M.termwin = nil
end

M.toggle = function()
	M.log("Toggling visibility")
	if M.is_visble then
		M.hide()
	else
		M.show()
	end
end

return M
