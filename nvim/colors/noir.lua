-- Neutral-first macOS adaptation of atraxsrc/cosmic-noir-theme.
-- Based on revision 6b2e9d97a99c4a8f8f20afe0687dc58802470c83.
-- Copyright (c) 2026 atraxsrc. MIT; see LICENSE.cosmic-noir.
local p = {
  bg = '#171717', panel = '#222222', raised = '#2A2A2A',
  text = '#D4D4D4', secondary = '#A0A0A0', comment = '#919191',
  directory = '#B8B8B8', link = '#B0B0B0', border = '#525252',
  accent = '#88A57D', warning = '#F56E0F', error = '#F25623',
}

vim.cmd.highlight('clear')
if vim.fn.exists('syntax_on') == 1 then vim.cmd.syntax('reset') end
vim.o.termguicolors = true
vim.o.background = 'dark'
vim.g.colors_name = 'noir'
local function hi(name, attributes) vim.api.nvim_set_hl(0, name, attributes) end

hi('Normal', { fg = p.text, bg = p.bg })
hi('NormalNC', { fg = p.text, bg = p.bg })
hi('NormalFloat', { fg = p.text, bg = p.panel })
hi('FloatBorder', { fg = p.border, bg = p.panel })
hi('FloatTitle', { fg = p.text, bg = p.panel, bold = true })
hi('CursorLine', { bg = p.panel })
hi('CursorColumn', { bg = p.panel })
hi('ColorColumn', { bg = p.panel })
hi('LineNr', { fg = p.comment })
hi('CursorLineNr', { fg = p.accent, bold = true })
hi('SignColumn', { bg = p.bg })
hi('FoldColumn', { fg = p.secondary, bg = p.bg })
hi('Folded', { fg = p.secondary, bg = p.panel })
hi('Visual', { bg = p.raised })
hi('VisualNOS', { bg = p.raised })
hi('Search', { fg = p.text, bg = p.raised, sp = p.accent, underline = true })
hi('IncSearch', { link = 'Search' })
hi('CurSearch', { link = 'Search' })
hi('Substitute', { link = 'Search' })
hi('MatchParen', { fg = p.accent, bold = true, underline = true })
hi('Cursor', { fg = p.bg, bg = p.accent })
hi('TermCursor', { link = 'Cursor' })
hi('NonText', { fg = p.comment })
hi('Whitespace', { fg = p.raised })
hi('EndOfBuffer', { fg = p.bg })
hi('SpecialKey', { fg = p.comment })
hi('Conceal', { fg = p.comment })
hi('Directory', { fg = p.directory })
hi('Title', { fg = p.text, bold = true })
hi('Question', { fg = p.text })
hi('MoreMsg', { fg = p.text })
hi('ModeMsg', { fg = p.secondary, bold = true })
hi('ErrorMsg', { fg = p.error, bold = true, underline = true })
hi('WarningMsg', { fg = p.warning })
hi('StatusLine', { fg = p.text, bg = p.panel })
hi('StatusLineNC', { fg = p.secondary, bg = p.panel })
hi('WinSeparator', { fg = p.border })
hi('VertSplit', { link = 'WinSeparator' })
hi('TabLine', { fg = p.secondary, bg = p.panel })
hi('TabLineSel', { fg = p.text, bg = p.raised, sp = p.accent, underline = true })
hi('TabLineFill', { bg = p.panel })
hi('WinBar', { fg = p.text, bg = p.bg })
hi('WinBarNC', { fg = p.secondary, bg = p.bg })
hi('Pmenu', { fg = p.text, bg = p.panel })
hi('PmenuSel', { fg = p.text, bg = p.raised, sp = p.accent, underline = true })
hi('PmenuSbar', { bg = p.panel })
hi('PmenuThumb', { bg = p.raised })
hi('PmenuKind', { fg = p.secondary, bg = p.panel })
hi('PmenuExtra', { fg = p.secondary, bg = p.panel })
hi('WildMenu', { link = 'PmenuSel' })
hi('QuickFixLine', { bg = p.raised, bold = true })
hi('SpellBad', { sp = p.error, bold = true, underline = true })
hi('SpellCap', { sp = p.warning, undercurl = true })
hi('SpellRare', { sp = p.secondary, undercurl = true })
hi('SpellLocal', { sp = p.secondary, undercurl = true })

-- Normal syntax is neutral; colour describes state, not language tokens.
hi('Comment', { fg = p.comment, italic = false })
hi('Constant', { fg = p.secondary })
hi('String', { fg = p.text })
hi('Character', { link = 'String' })
hi('Number', { fg = p.secondary })
hi('Boolean', { link = 'Number' })
hi('Float', { link = 'Number' })
hi('Identifier', { fg = p.text })
hi('Function', { fg = p.text })
hi('Statement', { fg = p.text })
hi('Operator', { fg = p.secondary })
hi('Keyword', { fg = p.text })
hi('PreProc', { fg = p.text })
hi('Type', { fg = p.directory })
hi('Special', { fg = p.text })
hi('Delimiter', { fg = p.secondary })
hi('SpecialComment', { fg = p.comment, bold = true })
hi('Debug', { fg = p.secondary })
hi('Underlined', { fg = p.link, underline = true })
hi('Ignore', { fg = p.comment })
hi('Error', { fg = p.error, bold = true, underline = true })
hi('Todo', { fg = p.secondary, bg = p.raised, bold = true })
hi('Added', { fg = p.text })
hi('Changed', { fg = p.secondary })
hi('Removed', { fg = p.error, bold = true, underline = true })
for name, target in pairs({
  Conditional = 'Keyword', Repeat = 'Keyword', Label = 'Keyword', Exception = 'Keyword',
  Include = 'PreProc', Define = 'PreProc', Macro = 'PreProc', PreCondit = 'PreProc',
  StorageClass = 'Type', Structure = 'Type', Typedef = 'Type',
  SpecialChar = 'Special', Tag = 'Keyword',
}) do hi(name, { link = target }) end

for name, target in pairs({
  ['@comment'] = 'Comment', ['@comment.todo'] = 'Todo',
  ['@string'] = 'String', ['@string.escape'] = 'Special',
  ['@string.regexp'] = 'Special', ['@string.special'] = 'Special',
  ['@string.special.url'] = 'Underlined', ['@character'] = 'Character',
  ['@number'] = 'Number', ['@number.float'] = 'Float', ['@boolean'] = 'Boolean',
  ['@constant'] = 'Constant', ['@constant.builtin'] = 'Constant', ['@constant.macro'] = 'Macro',
  ['@variable'] = 'Identifier', ['@variable.builtin'] = 'Identifier',
  ['@variable.parameter'] = 'Identifier', ['@variable.member'] = 'Identifier', ['@property'] = 'Identifier',
  ['@function'] = 'Function', ['@function.builtin'] = 'Function', ['@function.call'] = 'Function',
  ['@function.method'] = 'Function', ['@function.macro'] = 'Macro', ['@constructor'] = 'Type',
  ['@keyword'] = 'Keyword', ['@keyword.function'] = 'Keyword', ['@keyword.return'] = 'Keyword',
  ['@keyword.operator'] = 'Keyword', ['@keyword.import'] = 'Include',
  ['@keyword.conditional'] = 'Conditional', ['@keyword.repeat'] = 'Repeat',
  ['@keyword.exception'] = 'Exception', ['@keyword.directive'] = 'PreProc',
  ['@operator'] = 'Operator', ['@punctuation.delimiter'] = 'Delimiter',
  ['@punctuation.bracket'] = 'Delimiter', ['@punctuation.special'] = 'Special',
  ['@type'] = 'Type', ['@type.builtin'] = 'Type', ['@type.definition'] = 'Typedef',
  ['@attribute'] = 'Special', ['@module'] = 'Type', ['@label'] = 'Label',
  ['@tag'] = 'Tag', ['@tag.attribute'] = 'Identifier', ['@tag.delimiter'] = 'Delimiter',
  ['@markup.heading'] = 'Title', ['@markup.heading.1'] = 'Title',
  ['@markup.heading.2'] = 'Title', ['@markup.heading.3'] = 'Title',
  ['@markup.link'] = 'Underlined', ['@markup.link.label'] = 'Underlined', ['@markup.link.url'] = 'Underlined',
  ['@markup.raw'] = 'String', ['@markup.raw.block'] = 'String', ['@markup.math'] = 'Special',
  ['@markup.list'] = 'Delimiter', ['@diff.plus'] = 'Added', ['@diff.minus'] = 'Removed',
  ['@diff.delta'] = 'Changed',
}) do hi(name, { link = target }) end
hi('@comment.error', { fg = p.error, bg = p.raised, bold = true, underline = true })
hi('@comment.warning', { fg = p.warning, bg = p.raised })
hi('@comment.note', { fg = p.secondary, bg = p.raised })
hi('@markup.strong', { bold = true })
hi('@markup.italic', { italic = true })
hi('@markup.strikethrough', { strikethrough = true })
hi('@markup.underline', { underline = true })
hi('@markup.quote', { fg = p.secondary, italic = true })
hi('@markup.list.checked', { fg = p.accent })
hi('@markup.list.unchecked', { fg = p.secondary })

hi('DiagnosticError', { fg = p.error, bold = true, underline = true })
hi('DiagnosticWarn', { fg = p.warning })
hi('DiagnosticInfo', { fg = p.secondary })
hi('DiagnosticHint', { fg = p.secondary })
hi('DiagnosticOk', { fg = p.accent })
hi('DiagnosticUnderlineError', { sp = p.error, bold = true, underline = true })
hi('DiagnosticUnderlineWarn', { sp = p.warning, undercurl = true })
hi('DiagnosticUnderlineInfo', { sp = p.secondary, undercurl = true })
hi('DiagnosticUnderlineHint', { sp = p.secondary, undercurl = true })
hi('DiagnosticVirtualTextError', { fg = p.error, bg = p.panel, bold = true, underline = true })
hi('DiagnosticVirtualTextWarn', { fg = p.warning, bg = p.panel })
hi('DiagnosticVirtualTextInfo', { fg = p.secondary, bg = p.panel })
hi('DiagnosticVirtualTextHint', { fg = p.secondary, bg = p.panel })
hi('LspReferenceText', { bg = p.raised })
hi('LspReferenceRead', { bg = p.raised })
hi('LspReferenceWrite', { bg = p.raised, underline = true })
hi('LspInlayHint', { fg = p.comment, bg = p.panel })
hi('LspCodeLens', { fg = p.comment })
hi('LspSignatureActiveParameter', { fg = p.accent, bold = true })
hi('DiffAdd', { bg = p.panel, fg = p.text })
hi('DiffChange', { bg = p.panel })
hi('DiffDelete', { bg = p.panel, fg = p.error, bold = true, underline = true })
hi('DiffText', { bg = p.raised, bold = true })
hi('GitSignsAdd', { fg = p.accent })
hi('GitSignsChange', { fg = p.warning })
hi('GitSignsDelete', { fg = p.error })

hi('TelescopeNormal', { fg = p.text, bg = p.panel })
hi('TelescopeBorder', { fg = p.border, bg = p.panel })
hi('TelescopeSelection', { bg = p.raised })
hi('TelescopeMatching', { fg = p.accent, bold = true })
hi('SnacksPickerMatch', { fg = p.accent, bold = true })
hi('SnacksIndent', { fg = p.raised })
hi('SnacksIndentScope', { fg = p.border })
hi('IblIndent', { fg = p.raised })
hi('IblScope', { fg = p.border })
hi('WhichKey', { fg = p.accent })
hi('WhichKeyGroup', { fg = p.directory })
hi('WhichKeyDesc', { fg = p.text })
hi('WhichKeySeparator', { fg = p.secondary })
hi('NoiceCmdlinePopupBorder', { fg = p.border })
hi('NotifyBackground', { bg = p.bg })
hi('BlinkCmpMenu', { fg = p.text, bg = p.panel })
hi('BlinkCmpMenuBorder', { fg = p.border, bg = p.panel })
hi('BlinkCmpMenuSelection', { bg = p.raised })
hi('BlinkCmpLabelMatch', { fg = p.accent, bold = true })
hi('CmpItemAbbrMatch', { fg = p.accent, bold = true })
hi('NeoTreeNormal', { fg = p.text, bg = p.bg })
hi('NeoTreeDirectoryIcon', { fg = p.directory })
hi('NeoTreeDirectoryName', { fg = p.directory })
hi('NeoTreeFileName', { fg = p.text })
hi('NeoTreeSymbolicLinkTarget', { fg = p.link })
hi('NeoTreeGitModified', { fg = p.secondary })
hi('NeoTreeGitAdded', { fg = p.text })
hi('NeoTreeGitDeleted', { fg = p.error })
for _, mode in ipairs({ 'Normal', 'Insert', 'Visual', 'Replace', 'Command', 'Other' }) do
  hi('MiniStatuslineMode' .. mode, { fg = p.text, bg = p.raised, sp = p.accent, underline = true })
end
hi('MiniStatuslineFilename', { fg = p.text, bg = p.panel })
hi('BufferLineIndicatorSelected', { fg = p.accent })
hi('BufferLineBufferSelected', { fg = p.text, bg = p.raised, sp = p.accent, underline = true })
hi('FlashLabel', { fg = p.accent, bg = p.raised, bold = true })
hi('FlashMatch', { fg = p.text, bg = p.raised })
hi('LazyNormal', { fg = p.text, bg = p.panel })
hi('MasonNormal', { fg = p.text, bg = p.panel })
hi('DashboardHeader', { fg = p.text })
hi('SnacksDashboardHeader', { fg = p.text })
hi('SnacksDashboardIcon', { fg = p.secondary })
hi('SnacksDashboardKey', { fg = p.text })
hi('SnacksDashboardDesc', { fg = p.text })
hi('SnacksDashboardFooter', { fg = p.secondary })

local terminal = {
  '#222222', '#F25623', '#88A57D', '#F56E0F', '#B8B8B8', '#B0B0B0', '#A0A0A0', '#D4D4D4',
  '#919191', '#F25623', '#88A57D', '#F56E0F', '#B8B8B8', '#B0B0B0', '#D4D4D4', '#D4D4D4',
}
for index, color in ipairs(terminal) do vim.g['terminal_color_' .. (index - 1)] = color end
