import os

import matplotlib.pyplot as plt
import numpy as np


def load_waves(selected_waves):
    """
    读取地震时程数据
    :param selected_waves: 地震时程数据文件列表
    :return: 地震时程数据列表[(时程时间, 时程加速度, 时程名称)]
    """
    selected_waves = selected_waves if isinstance(selected_waves, list) else [selected_waves]
    waves = []
    for selected_wave in selected_waves:
        assert isinstance(selected_wave, dict)
        skiprows = selected_wave.get("skiprows", 0)
        wave_data = np.loadtxt(selected_wave[0]) if np.loadtxt(selected_wave[0], max_rows=1).reshape((-1,))[0] < 300 else np.loadtxt(selected_wave[0], skiprows=1)
        wave_data = wave_data if wave_data.ndim == 1 else wave_data[:, 1]
        # 归一化
        wave_data = wave_data / np.max(np.abs(wave_data))
        Tw = np.arange(0, np.round(len(wave_data) * selected_wave[1], len(str(selected_wave[1]).split(".")[1])), selected_wave[1])  # 时程时间
        waves.append((Tw, wave_data, selected_wave[2] if len(selected_wave) == 3 else os.path.splitext(os.path.basename(selected_wave[0]))[0]))
    return waves


def plot_waves(waves):
    """
    绘制地震时程数据
    :param waves: 地震时程数据列表
    :return: None
    """
    y_major_ticks = np.arange(-1, 1.1, 0.25)
    for wave in waves:
        fig = plt.figure(figsize=(12, 6))
        ax = fig.add_subplot(1, 1, 1)
        ax.plot(wave[0], wave[1], linewidth=1, alpha=0.8)
        ax.grid(which='major', alpha=0.7)
        ax.set_title(wave[2])
        ax.set_xlabel("t(s)")
        ax.set_ylabel("a(m/s^2)")
        ax.set_xlim(0, np.max(wave[0]))
        ax.set_ylim(-1, 1)
        ax.set_yticks(y_major_ticks)
    plt.show()
