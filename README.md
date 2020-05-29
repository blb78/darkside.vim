# Useless.vim

Stay focus on useful informations by hidden useless.

This is a fork of [Limelight.vim](https://github.com/junegunn/limelight.vim).
My goal is to adapt his philosophy, using highlight, to my needs.

## Usage

- `Useless`.

### Stay focus on buffer

For stay focus on your active buffer, you just have to run `Useless` without any necessary settings.

### Stay focus on paragraph

If you want to narrow the useful informations, as just visualize a paragraph, you have to set :

> let g:useful_default_boundary_start = '^\s*$\n\zs'
> let g:useful_default_boundary_end = '^\s*$'
