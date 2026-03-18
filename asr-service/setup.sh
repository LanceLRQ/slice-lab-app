#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  Qwen3-ASR Service 环境初始化"
echo "=========================================="

# 1. 检查 Python3
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] 未找到 python3，请先安装 Python 3.10+"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "[INFO] Python 版本：$PYTHON_VERSION"

# 2. 创建 venv
if [ ! -d "venv" ]; then
    echo "[INFO] 创建虚拟环境..."
    python3 -m venv venv
else
    echo "[INFO] 虚拟环境已存在，跳过创建"
fi

source venv/bin/activate

# 3. 升级 pip
echo "[INFO] 升级 pip..."
pip install --upgrade pip

# 4. 安装 PyTorch（根据 GPU 情况）
if command -v nvidia-smi &> /dev/null; then
    echo "[INFO] 检测到 NVIDIA GPU，安装 CUDA 版 PyTorch..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
else
    echo "[INFO] 未检测到 GPU，安装 CPU 版 PyTorch..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
fi

# 5. 安装其他依赖
echo "[INFO] 安装项目依赖..."
pip install -r requirements.txt

# 6. 创建必要目录
mkdir -p models/asr/0.6b models/asr/1.7b models/align/0.6b models/vad/fsmn models/vad/fsmn-onnx models/punc/ct-transformer models/punc/ct-transformer-onnx logs

# 7. 选择模型下载方式
echo ""
echo "=========================================="
echo "  模型配置"
echo "=========================================="
echo ""
echo "请选择模型获取方式："
echo "  1) ModelScope（国内推荐，速度快）"
echo "  2) HuggingFace（国外源）"
echo "  3) 手动放置（跳过下载，自行准备模型文件）"
echo ""
read -p "请输入选项 [1/2/3]（默认 1）: " MODEL_CHOICE
MODEL_CHOICE=${MODEL_CHOICE:-1}

case $MODEL_CHOICE in
    1)
        MODEL_SOURCE="modelscope"
        echo "[INFO] 已选择 ModelScope 作为下载源"
        ;;
    2)
        MODEL_SOURCE="huggingface"
        echo "[INFO] 已选择 HuggingFace 作为下载源"
        echo "[INFO] 注意：VAD 和标点模型仅 ModelScope 提供，将自动从 ModelScope 下载"
        ;;
    3)
        MODEL_SOURCE="manual"
        echo "[INFO] 已选择手动模式"
        echo ""
        echo "=========================================="
        echo "  手动放置模型指引"
        echo "=========================================="
        echo ""
        echo "请将模型文件放入以下目录："
        echo ""
        echo "  Qwen3-ASR-0.6B（ASR 轻量，GPU VRAM 4-6GB）："
        echo "    → $(pwd)/models/asr/0.6b/"
        echo ""
        echo "  Qwen3-ASR-1.7B（ASR 完整，GPU VRAM >= 6GB）："
        echo "    → $(pwd)/models/asr/1.7b/"
        echo ""
        echo "  Qwen3-ForcedAligner-0.6B（字级别时间戳对齐）："
        echo "    → $(pwd)/models/align/0.6b/"
        echo ""
        echo "  VAD 模型（语音活动检测）："
        echo "    → $(pwd)/models/vad/fsmn/"
        echo ""
        echo "  标点模型（自动加标点）："
        echo "    → $(pwd)/models/punc/ct-transformer/"
        echo ""
        echo "模型来源："
        echo "  ModelScope:"
        echo "    https://modelscope.cn/models/Qwen/Qwen3-ASR-0.6B"
        echo "    https://modelscope.cn/models/Qwen/Qwen3-ASR-1.7B"
        echo "    https://modelscope.cn/models/Qwen/Qwen3-ForcedAligner-0.6B"
        echo "    https://modelscope.cn/models/iic/speech_fsmn_vad_zh-cn-16k-common-pytorch"
        echo "    https://modelscope.cn/models/iic/punc_ct-transformer_zh-cn-common-vocab272727-pytorch"
        echo ""
        echo "  HuggingFace（仅 ASR 和对齐模型，VAD/标点需从 ModelScope 获取）:"
        echo "    https://huggingface.co/Qwen/Qwen3-ASR-0.6B"
        echo "    https://huggingface.co/Qwen/Qwen3-ASR-1.7B"
        echo "    https://huggingface.co/Qwen/Qwen3-ForcedAligner-0.6B"
        echo ""
        echo "放置完成后执行 bash start.sh 启动服务。"
        echo "=========================================="
        ;;
    *)
        MODEL_SOURCE="modelscope"
        echo "[INFO] 无效选项，默认使用 ModelScope"
        ;;
esac

echo ""
echo "=========================================="
echo "  环境初始化完成"
echo "=========================================="
echo ""
echo "启动服务时请通过 --model-source 指定下载源："
echo "  bash start.sh --model-source $MODEL_SOURCE"
echo ""
