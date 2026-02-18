switch("define", "imagemanLibjpeg=off")
switch("define", "imagemanLibpng=off")

when defined(macosx):
  # https://github.com/treeform/puppy/issues/118
  switch("define", "puppyLibcurl")
# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
