import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import numpy as np
import os
import zipfile

## IMPORTANT: this can be use on google colab (make sure use type T4 GPU) for training ##

# 1. ARCHITECTURE 
model = models.Sequential([
    # Conv1: 4 filters, 5x5, ReLU (In: 28x28 -> Out: 24x24)
    layers.Conv2D(4, (5, 5), activation='relu', input_shape=(28, 28, 1), name='c1'),
    layers.MaxPooling2D((2, 2), name='p1'),

    # Conv2: 8 filters, 5x5, ReLU (In: 12x12x4 -> Out: 8x8x8)
    layers.Conv2D(8, (5, 5), activation='relu', name='c3'),
    layers.MaxPooling2D((2, 2), name='p2'),

    layers.Flatten(), # 4x4x8 = 128 nodes

    # Dense Layers (Row-major matching RTL)
    layers.Dense(32, activation='relu', name='f1'),
    layers.Dense(16, activation='relu', name='f2'),
    layers.Dense(10, name='out') #khong dung softmax
])

# 2. DATA AUGMENTATION 
datagen = ImageDataGenerator(
    rotation_range=12,
    width_shift_range=0.1,
    height_shift_range=0.1,
    zoom_range=0.1,
    shear_range=0.1
)

# 3. CHUẨN BỊ DỮ LIỆU MNIST
(x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()
x_train = x_train.reshape(-1, 28, 28, 1).astype('float32') / 255.0
x_test = x_test.reshape(-1, 28, 28, 1).astype('float32') / 255.0

# 4. TRAINING BEGIN (Accuracy expected > 97%)
model.compile(optimizer='adam',
              loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
              metrics=['accuracy'])

print("🚀 START AI TRAINING")
model.fit(datagen.flow(x_train, y_train, batch_size=128),
          epochs=15, validation_data=(x_test, y_test))

# 5. CONVERT TO Q6.10 (Signed 16-bit Hex)
def to_hex_q6_10(weights):
    # Nhân với 1024 (2^10) và chặn (clamping) trong dải của int16
    scaled = np.clip(np.round(weights * 1024), -32768, 32767).astype(np.int32)
    hex_list = []
    for val in scaled.flatten():
        if val < 0: val = (1 << 16) + val # Biến thành số bù 2
        hex_list.append(f"{val:04x}")
    return hex_list

def save_mem(filename, hex_data):
    with open(filename, 'w') as f:
        f.write("\n".join(hex_data))

# 6. EXPORT WEIGHTS
os.makedirs('weights_new', exist_ok=True)

# C1
c1_w, c1_b = model.get_layer('c1').get_weights()
save_mem('weights_new/c1_weight.mem', to_hex_q6_10(c1_w.transpose(3,0,1,2)))
save_mem('weights_new/c1_bias.mem', to_hex_q6_10(c1_b))

# C3 (Conv2)
c3_w, c3_b = model.get_layer('c3').get_weights()
save_mem('weights_new/c3_weight.mem', to_hex_q6_10(c3_w.transpose(3,2,0,1)))
save_mem('weights_new/c3_bias.mem', to_hex_q6_10(c3_b))

# F1, F2, Out
f1_w, f1_b = model.get_layer('f1').get_weights()
save_mem('weights_new/f1_weight.mem', to_hex_q6_10(f1_w))

f2_w, f2_b = model.get_layer('f2').get_weights()
save_mem('weights_new/f2_weight.mem', to_hex_q6_10(f2_w))

out_w, out_b = model.get_layer('out').get_weights()
save_mem('weights_new/out_weight.mem', to_hex_q6_10(out_w))

# 7. EXPORT BIAS
save_mem('weights_new/f1_bias.mem', to_hex_q6_10(f1_b))
save_mem('weights_new/f2_bias.mem', to_hex_q6_10(f2_b))
save_mem('weights_new/out_bias.mem', to_hex_q6_10(out_b))

# 8. ZIP AND DOWLOAD
with zipfile.ZipFile('weights_perfect.zip', 'w') as zipf:
    for root, dirs, files in os.walk('weights_new'):
        for file in files:
            zipf.write(os.path.join(root, file), file)

print("\n✅ XONG RỒI! Hãy tải file 'weights_perfect.zip' về và nạp vào project nhé!")