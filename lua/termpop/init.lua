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
			table.insert(line, { "|", "exred" })
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
	end
	if opts.toggle_keymap then
		vim.keymap.set(opts.toggle_keymap[1], opts.toggle_keymap[2], M.toggle)
	end
	if opts.new_term_keymap then
		vim.keymap.set(opts.new_term_keymap[1], opts.new_term_keymap[2],
			       opts.new_term_keymap[3] or M.add_term)
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
	if type(opts.border) == "boolean" then
		M.border = opts.border
	else
		M.border = true
	end
	M.size = opts.size
	M.name = opts.name or "Term"
	M.cmd = opts.cmd or { vim.o.shell }
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
			vim.schedule(function()
				M.delete_term(args.buf)
			end)
		end,
	})
end

M.next_term = function()
	if M.is_visible then
		for i, v in pairs(M.terminals) do
			if v.buf == M.cur_term.buf then
				if i == #M.terminals then
					M.cur_term = M.terminals[1]
				else
					M.cur_term = M.terminals[i + 1]
				end
				break
			end
		end
		local h = math.floor(vim.o.lines * (M.size.h / 100))
		local bar_row = math.floor((vim.o.lines - h) / 2)
		local w = math.floor(vim.o.columns * (M.size.w / 100))
		local bar_col = math.floor((vim.o.columns - w) / 2)

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
			height = h - 3 - 3, -- 3 for bar, 3 bottom padding
			relative = "editor",
			style = "minimal",
			border = M.border and "single" or colored_border,
			zindex = 100,
		}
		if vim.api.nvim_win_is_valid(M.termwin) then
			vim.api.nvim_win_close(M.termwin, false)
		end
		M.termwin = vim.api.nvim_open_win(M.cur_term.buf, true, term_win_opts)
		if M.border then
			vim.wo[M.termwin].winhl = "Normal:normal,floatborder:comment"
		else
			vim.wo[M.termwin].winhl = "Normal:exdarkbg,floatBorder:exdarkborder"
		end

		volt.redraw(M.barbuf, "bar")
		vim.cmd.startinsert()
	else
		M.toggle()
	end
end

M.prev_term = function()
	if M.is_visible then
		for i, v in pairs(M.terminals) do
			if v.buf == M.cur_term.buf then
				if i == 1 then
					M.cur_term = M.terminals[#M.terminals]
				else
					M.cur_term = M.terminals[i - 1]
				end
				break
			end
		end
		local h = math.floor(vim.o.lines * (M.size.h / 100))
		local bar_row = math.floor((vim.o.lines - h) / 2)
		local w = math.floor(vim.o.columns * (M.size.w / 100))
		local bar_col = math.floor((vim.o.columns - w) / 2)

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
			height = h - 3 - 3, -- 3 for bar, 3 bottom padding
			relative = "editor",
			style = "minimal",
			border = M.border and "single" or colored_border,
			zindex = 100,
		}
		if vim.api.nvim_win_is_valid(M.termwin) then
			vim.api.nvim_win_close(M.termwin, false)
		end
		M.termwin = vim.api.nvim_open_win(M.cur_term.buf, true, term_win_opts)
		if M.border then
			vim.wo[M.termwin].winhl = "Normal:normal,floatborder:comment"
		else
			vim.wo[M.termwin].winhl = "Normal:exdarkbg,floatBorder:exdarkborder"
		end

		volt.redraw(M.barbuf, "bar")
		vim.cmd.startinsert()

	else
		M.toggle()
	end
end

M.delete_term = function(buf)
	local h = math.floor(vim.o.lines * (M.size.h / 100))
	local bar_row = math.floor((vim.o.lines - h) / 2)
	local w = math.floor(vim.o.columns * (M.size.w / 100))
	local bar_col = math.floor((vim.o.columns - w) / 2)

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
		height = h - 3 - 3, -- 3 for bar, 3 bottom padding
		relative = "editor",
		style = "minimal",
		border = M.border and "single" or colored_border,
		zindex = 100,
	}

	for i, v in pairs(M.terminals) do
		if v.buf == buf then
			table.remove(M.terminals, i)
			volt.redraw(M.barbuf, "bar")
			if v.buf == M.cur_term.buf then
				M.cur_term = nil
				if #M.terminals == 0 then
				elseif #M.terminals < i then
					M.cur_term = M.terminals[#M.terminals]
				else
					M.cur_term = M.terminals[i]
				end
			end
			if M.is_visible then
				if #M.terminals == 0 then
					M.is_visible = nil
					vim.api.nvim_win_close(M.barwin, false)
					M.barwin = nil
					if vim.api.nvim_win_is_valid(M.termwin) then
						vim.api.nvim_win_close(M.termwin, false)
					end
					M.termwin = nil
					volt.redraw(M.barbuf, "bar")
					return
				else
					if vim.api.nvim_win_is_valid(M.termwin) then
						vim.api.nvim_win_close(M.termwin, false)
					end
					M.termwin = vim.api.nvim_open_win(M.cur_term.buf, true,
									  term_win_opts)
					if M.border then
						vim.wo[M.termwin].winhl = "Normal:normal,floatborder:comment"
					else
						vim.wo[M.termwin].winhl = "Normal:exdarkbg,floatBorder:exdarkborder"
					end
					volt.redraw(M.barbuf, "bar")
					vim.cmd.startinsert()
				end
			end
			volt.redraw(M.barbuf, "bar")
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
		name = opts.name or M.name,
		buf = vim.api.nvim_create_buf(false, true),
		cmd = opts.cmd or M.cmd,
	}
	vim.keymap.set({"n", "t"}, "<C-Del>",
		       function()
				for i, v in pairs(M.terminals) do
					if v.buf == term.buf then
						vim.api.nvim_buf_delete(term.buf, { force = true })
						M.delete_term(term.buf)
						return
					end
				end
				vim.notify("Term buf not found for deletion: " .. term.buf)
		       end,
		       { buffer = term.buf })
	return term
end

M.add_term = function(opts)
	local term = M.new_term_buf(opts)
	table.insert(M.terminals, term)
	M.cur_term = term
	local cur_buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_set_current_buf(term.buf)
	vim.fn.jobstart(term.cmd, { term = true })
	vim.api.nvim_set_current_buf(cur_buf)

	volt.redraw(M.barbuf, "bar")

	if not M.is_visible then
		M.show()
	else
		if #M.terminals == 1 then
			return
		else
			local h = math.floor(vim.o.lines * (M.size.h / 100))
			local bar_row = math.floor((vim.o.lines - h) / 2)
			local w = math.floor(vim.o.columns * (M.size.w / 100))
			local bar_col = math.floor((vim.o.columns - w) / 2)

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
				height = h - 3 - 3, -- 3 for bar, 3 bottom padding
				relative = "editor",
				style = "minimal",
				border = M.border and "single" or colored_border,
				zindex = 100,
			}
			if vim.api.nvim_win_is_valid(M.termwin) then
				vim.api.nvim_win_close(M.termwin, false)
			end
			M.termwin = vim.api.nvim_open_win(M.cur_term.buf, true, term_win_opts)
			if M.border then
				vim.wo[M.termwin].winhl = "Normal:normal,floatborder:comment"
			else
				vim.wo[M.termwin].winhl = "Normal:exdarkbg,floatBorder:exdarkborder"
			end

			volt.redraw(M.barbuf, "bar")
			vim.cmd.startinsert()
		end
	end
end

M.show = function()
	M.is_visible = true

	local h = math.floor(vim.o.lines * (M.size.h / 100))
	local bar_row = math.floor((vim.o.lines - h) / 2)
	local w = math.floor(vim.o.columns * (M.size.w / 100))
	local bar_col = math.floor((vim.o.columns - w) / 2)

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
		height = h - 3 - 3, -- 3 for bar, 3 bottom padding
		relative = "editor",
		style = "minimal",
		border = M.border and "single" or colored_border,
		zindex = 100,
	}

	if #M.terminals == 0 then
		M.add_term()
	end

	M.barwin = vim.api.nvim_open_win(M.barbuf, false, bar_win_opts)
	if M.border then
		vim.wo[M.barwin].winhl = "Normal:normal,floatborder:exred"
	else
		vim.wo[M.barwin].winhl = "Normal:exdarkbg,floatBorder:exdarkborder"
	end

	vim.api.nvim_set_hl(M.ns, "floatBorder", { link = M.border and "comment" or "exblack2border" })
	vim.api.nvim_set_hl(M.ns, "Normal", { link = M.border and "normal" or "exblack2bg" })
	vim.api.nvim_set_option_value("modifiable", true, { buf = M.barbuf })

	M.termwin = vim.api.nvim_open_win(M.cur_term.buf, true, term_win_opts)
	if M.border then
		vim.wo[M.termwin].winhl = "Normal:normal,floatborder:comment"
	else
		vim.wo[M.termwin].winhl = "Normal:exdarkbg,floatBorder:exdarkborder"
	end

	volt.run(M.barbuf, { h = 1, w = bar_win_opts.width })
	volt.redraw(M.barbuf, "bar")
	vim.cmd.startinsert()
end

M.hide = function()
	M.is_visible = nil
	vim.api.nvim_win_close(M.barwin, false)
	M.barwin = nil
	vim.api.nvim_win_close(M.termwin, false)
	M.termwin = nil
end

M.find_term = function(term_name)
	for i, v in pairs(M.terminals) do
		if v.name == term_name then
			return i, v
		end
	end
end

M.toggle = function()
	if M.is_visible then
		M.hide()
	else
		M.show()
	end
end

M.send_to_cur_terminal = function(str)
	if M.cur_term then
		vim.api.nvim_chan_send(vim.b[M.cur_term.buf].terminal_job_id, str)
	else
		print("No terminal to send to")
	end
end

M.send_to_term = function(term_name, str)
	local i, term = M.find_term(term_name)
	if term then
		vim.api.nvim_chan_send(vim.b[term.buf].terminal_job_id, str)
	else
		print("Terminal not found: " .. term_name)
	end
end

M.show_term = function(buf)
	for i, v in pairs(M.terminals) do
		if v.buf == buf then
			if M.is_visible then
				M.cur_term = v
				local h = math.floor(vim.o.lines * (M.size.h / 100))
				local bar_row = math.floor((vim.o.lines - h) / 2)
				local w = math.floor(vim.o.columns * (M.size.w / 100))
				local bar_col = math.floor((vim.o.columns - w) / 2)

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
					height = h - 3 - 3, -- 3 for bar, 3 bottom padding
					relative = "editor",
					style = "minimal",
					border = M.border and "single" or colored_border,
					zindex = 100,
				}
				if vim.api.nvim_win_is_valid(M.termwin) then
					vim.api.nvim_win_close(M.termwin, false)
				end
				M.termwin = vim.api.nvim_open_win(M.cur_term.buf, true, term_win_opts)
				if M.border then
					vim.wo[M.termwin].winhl = "Normal:normal,floatborder:comment"
				else
					vim.wo[M.termwin].winhl = "Normal:exdarkbg,floatBorder:exdarkborder"
				end

				volt.redraw(M.barbuf, "bar")
				vim.cmd.startinsert()
				return
			else
				M.cur_term = v
				M.show()
				return
			end
		end
	end
	print("Buffer not found")
end

return M
