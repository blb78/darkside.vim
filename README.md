# Useless.vim

Stay focus on useful informations by hidden useless.

This is a fork of [Limelight.vim](https://github.com/junegunn/limelight.vim).
My goal is to adapt his philosophy, using highlight, to my needs.

## Usage

- `Useless`.

### Stay focus on buffer

For stay focus on your active buffer, you just have to run `Useless` without any necessary settings.
Or maybe you can play with opacity.

```vim
" default 0.5
let g:useless_opacity = 0.3

```

### Stay focus on paragraph

If you want to narrow the useful informations, as just visualize a paragraph, you have to set patterns in order to define where start and end an useful paragraph:

```vim

let g:useless_opacity = 0.3
let g:useful_default_boundary_start = '^\s*$\n\zs'
let g:useful_default_boundary_end = '^\s*$'

```

### Filetypes

So, you have set default boundary to display only useful informations. But for your Go files, default patterns are not suitable.

```vim

let g:useless_opacity = 0.3
let g:useful_default_boundary_start = '^\s*$\n\zs'
let g:useful_default_boundary_end = '^\s*$'
let g:useful_filetypes = {'go':{'boundary_start':'^\w.*$','boundary_end':'\(^.$\|func.*{.*}$\)'}}

```

### Groups

You'll not define patterns for each  filetype that you are using. But you can define groups and apply patterns for a list of filetypes.


```vim

let g:useless_opacity = 0.3
let g:useful_default_boundary_start = '^\s*$\n\zs'
let g:useful_default_boundary_end = '^\s*$'
let g:useful_groups = {
			\'prose':{
			\	'filetypes':['markdown','tex'],
			\	'boundary_start':'\(\([.!?#>-]\s\)\@<=.\|\(^\t\)\@<=\w\|^[A-Z0-9]\)',
			\	'boundary_end':'\(\([.!?]\s\)\@=\|\(\n$\)\@=\)'},
			\}
let g:useful_filetypes = {'go':{'boundary_start':'^\w.*$','boundary_end':'\(^.$\|func.*{.*}$\)'}}

```

Oh yeah but for particular files, I just want the basic usage, without patterns for narrowing.

```vim

let g:useless_opacity = 0.3
let g:useful_default_boundary_start = '^\s*$\n\zs'
let g:useful_default_boundary_end = '^\s*$'
let g:useful_groups = {
			\'prose':{
			\	'filetypes':['markdown','tex'],
			\	'boundary_start':'\(\([.!?#>-]\s\)\@<=.\|\(^\t\)\@<=\w\|^[A-Z0-9]\)',
			\	'boundary_end':'\(\([.!?]\s\)\@=\|\(\n$\)\@=\)'},
			\'basic_usage' : {
			\	'filetypes':['make','yaml'],
			\	'boundary_start':'',
			\	'boundary_end':''},
			\}
let g:useful_filetypes = {'go':{'boundary_start':'^\w.*$','boundary_end':'\(^.$\|func.*{.*}$\)'}}

```
