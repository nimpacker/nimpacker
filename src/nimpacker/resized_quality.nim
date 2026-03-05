## High-quality resize for icon generation
## Improved algorithm for small icon sizes

import imageman/[images, colors]
import math

proc gaussianBlur*[T: Color](img: Image[T], radius: float): Image[T] =
  ## Apply gaussian blur to reduce aliasing before downscaling
  let kernelSize = max(3, int(radius * 2) * 2 + 1)
  let sigma = radius
  var kernel = newSeq[float](kernelSize)
  let mid = kernelSize div 2
  var sum = 0.0
  
  for i in 0..<kernelSize:
    let x = float(i - mid)
    kernel[i] = exp(-(x * x) / (2.0 * sigma * sigma))
    sum += kernel[i]
  
  # Normalize kernel
  for i in 0..<kernelSize:
    kernel[i] /= sum
  
  # Apply horizontal pass
  var temp = initImage[T](img.width, img.height)
  for y in 0..<img.height:
    for x in 0..<img.width:
      var r, g, b, a: float
      for i in 0..<kernelSize:
        let srcX = clamp(x + i - mid, 0, img.width - 1)
        let weight = kernel[i]
        let c = img[srcX, y]
        r += c[0].float * weight
        g += c[1].float * weight  
        b += c[2].float * weight
        a += c[3].float * weight
      when T is ColorRGBAU:
        temp[x, y] = T([r.clamp(0, 255).uint8, g.clamp(0, 255).uint8, b.clamp(0, 255).uint8, a.clamp(0, 255).uint8])
  
  # Apply vertical pass
  result = initImage[T](img.width, img.height)
  for y in 0..<img.height:
    for x in 0..<img.width:
      var r, g, b, a: float
      for i in 0..<kernelSize:
        let srcY = clamp(y + i - mid, 0, img.height - 1)
        let weight = kernel[i]
        let c = temp[x, srcY]
        r += c[0].float * weight
        g += c[1].float * weight
        b += c[2].float * weight
        a += c[3].float * weight
      when T is ColorRGBAU:
        result[x, y] = T([r.clamp(0, 255).uint8, g.clamp(0, 255).uint8, b.clamp(0, 255).uint8, a.clamp(0, 255).uint8])

proc sharpen*[T: Color](img: Image[T], amount: float = 0.5): Image[T] =
  ## Apply sharpening filter to enhance edges after downscaling
  result = initImage[T](img.width, img.height)
  
  for y in 0..<img.height:
    for x in 0..<img.width:
      var r, g, b, a: float
      
      # Center pixel (weight = 1 + 4*amount)
      let center = img[x, y]
      r += center[0].float * (1.0 + 4.0 * amount)
      g += center[1].float * (1.0 + 4.0 * amount)
      b += center[2].float * (1.0 + 4.0 * amount)
      a += center[3].float * (1.0 + 4.0 * amount)
      
      # Neighbors (weight = -amount)
      let neighbors = [
        (x, y-1), (x-1, y), (x+1, y), (x, y+1)
      ]
      
      for (nx, ny) in neighbors:
        let sx = clamp(nx, 0, img.width - 1)
        let sy = clamp(ny, 0, img.height - 1)
        let c = img[sx, sy]
        r -= c[0].float * amount
        g -= c[1].float * amount
        b -= c[2].float * amount
        a -= c[3].float * amount
      
      when T is ColorRGBAU:
        result[x, y] = T([r.clamp(0, 255).uint8, g.clamp(0, 255).uint8, b.clamp(0, 255).uint8, a.clamp(0, 255).uint8])

proc lanczosKernel(x: float, a: int = 3): float =
  ## Lanczos resampling kernel
  let absX = abs(x)
  if absX < 1e-7:
    return 1.0
  if absX >= a.float:
    return 0.0
  let pix = PI * absX
  return (a.float * sin(pix) * sin(pix / a.float)) / (pix * pix)

proc resizedLanczos*[T: Color](img: Image[T], newWidth, newHeight: int, a: int = 3): Image[T] =
  ## High-quality Lanczos resampling
  result = initImage[T](newWidth, newHeight)
  
  let xScale = img.width.float / newWidth.float
  let yScale = img.height.float / newHeight.float
  
  for y in 0..<newHeight:
    for x in 0..<newWidth:
      var r, g, b, aSum: float
      var weightSum: float
      
      let srcX = (x.float + 0.5) * xScale - 0.5
      let srcY = (y.float + 0.5) * yScale - 0.5
      
      let xStart = max(0, int(ceil(srcX - a.float)))
      let xEnd = min(img.width - 1, int(floor(srcX + a.float)))
      let yStart = max(0, int(ceil(srcY - a.float)))
      let yEnd = min(img.height - 1, int(floor(srcY + a.float)))
      
      for sy in yStart..yEnd:
        let dy = srcY - sy.float
        let wy = lanczosKernel(dy, a)
        if wy == 0: continue
        
        for sx in xStart..xEnd:
          let dx = srcX - sx.float
          let wx = lanczosKernel(dx, a)
          if wx == 0: continue
          
          let w = wx * wy
          let c = img[sx, sy]
          r += c[0].float * w
          g += c[1].float * w
          b += c[2].float * w
          aSum += c[3].float * w
          weightSum += w
      
      if weightSum > 0:
        r /= weightSum
        g /= weightSum
        b /= weightSum
        aSum /= weightSum
      
      when T is ColorRGBAU:
        result[x, y] = T([r.clamp(0, 255).uint8, g.clamp(0, 255).uint8, b.clamp(0, 255).uint8, aSum.clamp(0, 255).uint8])

proc resizedHighQuality*[T: Color](img: Image[T], targetSize: int): Image[T] =
  ## High-quality resize optimized for icon generation
  ## Uses pre-blur + Lanczos for extreme downscaling, with post-sharpen for small sizes
  
  let currentSize = img.width
  
  # For small increases or decreases, use Lanczos directly
  if currentSize <= targetSize * 2 and targetSize >= 64:
    return img.resizedLanczos(targetSize, targetSize)
  
  # For extreme downscaling to very small sizes (16x16, 32x32)
  if targetSize <= 64:
    # Apply slight blur first to reduce aliasing
    let blurRadius = max(0.5, (currentSize.float / targetSize.float) * 0.3)
    var temp = img.gaussianBlur(blurRadius)
    
    # Use pyramid approach for large ratios
    var current = currentSize
    while current > targetSize * 2:
      current = current div 2
      temp = temp.resizedLanczos(current, current)
    
    # Final resize
    if current != targetSize:
      temp = temp.resizedLanczos(targetSize, targetSize)
    
    # Sharpen small icons to enhance edges
    if targetSize <= 32:
      temp = temp.sharpen(0.3)
    
    return temp
  
  # For medium downscaling, use pyramid Lanczos
  var temp = img
  var current = currentSize
  
  while current > targetSize * 2:
    current = current div 2
    temp = temp.resizedLanczos(current, current)
  
  if current != targetSize:
    temp = temp.resizedLanczos(targetSize, targetSize)
  
  return temp
