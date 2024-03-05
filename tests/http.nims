import os

const win_amd64_driver = "https://storage.googleapis.com/chrome-for-testing-public/122.0.6261.57/win64/chromedriver-win64.zip"

let resp = httpGet(win_amd64_driver)

writeFile("tmp.zip", resp.body)