import os
import logging
from app.config import MODEL_SOURCE

logger = logging.getLogger(__name__)


def ensure_model(repo_id: str, local_dir: str):
    """
    确保模型已下载到本地。
    根据 MODEL_SOURCE 配置选择下载源，目录非空则跳过。
    """
    if os.path.exists(local_dir) and os.listdir(local_dir):
        logger.info(f"模型已存在: {local_dir}")
        return

    if MODEL_SOURCE == "manual":
        raise FileNotFoundError(
            f"模型未找到: {local_dir}\n"
            f"当前配置为手动模式，请将模型文件放入该目录后重启服务。"
        )

    logger.info(f"开始下载模型 [{MODEL_SOURCE}]: {repo_id} -> {local_dir}")
    os.makedirs(local_dir, exist_ok=True)

    if MODEL_SOURCE == "modelscope":
        from modelscope import snapshot_download
        snapshot_download(
            model_id=repo_id,
            local_dir=local_dir,
        )
    else:
        from huggingface_hub import snapshot_download
        snapshot_download(
            repo_id=repo_id,
            local_dir=local_dir,
        )

    logger.info(f"模型下载完成: {local_dir}")


def ensure_model_modelscope(repo_id: str, local_dir: str):
    """
    强制从 ModelScope 下载模型（用于仅 ModelScope 提供的模型，如 VAD、标点）。
    手动模式下同样要求用户自行放置。
    """
    if os.path.exists(local_dir) and os.listdir(local_dir):
        logger.info(f"模型已存在: {local_dir}")
        return

    if MODEL_SOURCE == "manual":
        raise FileNotFoundError(
            f"模型未找到: {local_dir}\n"
            f"当前配置为手动模式，请将模型文件放入该目录后重启服务。\n"
            f"下载地址: https://modelscope.cn/models/{repo_id}"
        )

    logger.info(f"开始下载模型 [modelscope]: {repo_id} -> {local_dir}")
    os.makedirs(local_dir, exist_ok=True)

    from modelscope import snapshot_download
    snapshot_download(
        model_id=repo_id,
        local_dir=local_dir,
    )

    logger.info(f"模型下载完成: {local_dir}")
