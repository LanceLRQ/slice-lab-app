import os

# 读取 HTML 模板文件
_TPL_PATH = os.path.join(os.path.dirname(__file__), "index.html")
HTML_PAGE = open(_TPL_PATH, encoding="utf-8").read()
