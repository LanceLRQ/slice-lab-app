import os
import logging
from app.config import LOG_FILE, LOG_DIR


def setup_logger():
    """配置全局日志"""
    os.makedirs(LOG_DIR, exist_ok=True)

    root = logging.getLogger()
    root.setLevel(logging.INFO)

    # 清除已有 handler，避免第三方库提前配置导致 basicConfig 不生效
    root.handlers.clear()

    formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s")

    file_handler = logging.FileHandler(LOG_FILE, encoding="utf-8")
    file_handler.setFormatter(formatter)
    root.addHandler(file_handler)

    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)
    root.addHandler(stream_handler)
