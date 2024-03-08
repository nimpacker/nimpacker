switch("define", "imagemanLibjpeg=off")
switch("define", "imagemanLibpng=off")

when defined(macosx):
  # https://github.com/treeform/puppy/issues/118
  switch("define", "puppyLibcurl")