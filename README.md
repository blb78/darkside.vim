# Useless.vim

Stay focus on useful informations by hidden useless.

This is a fork of [Limelight.vim](https://github.com/junegunn/limelight.vim).
My goal is to adapt his philosophy, using highlight, to my needs.

## Usage

- `Useless`.

### Stay focus on buffer

For stay focus on your active buffer, you just have to run `Useless` without any necessary settings.

### Stay focus on paragraph

If you want to narrow the useful informations, as just visualize a paragraph, you have to set patterns in order to define where start and end an useful paragraph:

```

let g:useful_default_boundary_start = '^\s*$\n\zs'
let g:useful_default_boundary_end = '^\s*$'

```

### Filetypes

So, you have set default boundary to display only useful informations. But for your Go files, default patterns are not suitable.

```

let g:useful_default_boundary_start = '^\s*$\n\zs'
let g:useful_default_boundary_end = '^\s*$'
let g:useful_filetypes = {'go':{'boundary_start':'^\w.*$','boundary_end':'\(^.$\|func.*{.*}$\)'}}

```

