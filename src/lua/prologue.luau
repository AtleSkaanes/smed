type Opts = { [string]: string } | nil

Smed = {}

Smed.raw_html = ''

function Smed.write(raw_html: string)
	Smed.raw_html = Smed.raw_html .. raw_html
end

local function opts_to_str(opts: Opts)
	opts = opts or {}

	local opts_str = ''
	for key, value in pairs(opts) do
		opts_str = opts_str .. key .. '="' .. value .. '" '
	end

	if opts_str ~= '' then
		opts_str = opts_str:sub(1, -2)
		opts_str = ' ' .. opts_str
	end

	return opts_str
end

--- HTML HELPERS ---

function Smed.p(inner: string, opts: Opts): string
	return '<p' .. opts_to_str(opts) .. '>' .. inner .. '</p>\n'
end

function Smed.h1(inner: string, opts: Opts): string
	return '<h1' .. opts_to_str(opts) .. '>' .. inner .. '</h2>\n'
end

function Smed.h2(inner: string, opts: Opts): string
	return '<h2' .. opts_to_str(opts) .. '>' .. inner .. '</h2>\n'
end

function Smed.h3(inner: string, opts: Opts): string
	return '<h3' .. opts_to_str(opts) .. '>' .. inner .. '</h3>\n'
end

function Smed.h4(inner: string, opts: Opts): string
	return '<h4' .. opts_to_str(opts) .. '>' .. inner .. '</h4>\n'
end

function Smed.bold(inner: string, opts: Opts): string
	return '<strong' .. opts_to_str(opts) .. '>' .. inner .. '</strong>\n'
end

function Smed.italic(inner: string, opts: Opts): string
	return '<em' .. opts_to_str(opts) .. '>' .. inner .. '</em>\n'
end

function Smed.button(onclick: string, inner: string, opts: Opts): string
	opts = opts or {}
	opts['onclick'] = onclick
	return '<button' .. opts_to_str(opts) .. '>' .. inner .. '</button>\n'
end

function Smed.img(src: string, alt: string, opts: Opts): string
	opts = opts or {}
	opts['src'] = src
	opts['alt'] = alt
	return '<img' .. opts_to_str(opts) .. '>\n'
end

function Smed.div(inner: string, opts: Opts): string
	return '<div' .. opts_to_str(opts) .. '>' .. inner .. '</div>\n'
end


