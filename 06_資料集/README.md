# 06_資料集

論文用五個 32×32×3、10 類公開影像資料集。實際資料由 `05_程式碼/AI_model_train` 的 loader
（torchvision / 內建下載程序）自動取得,本資料夾僅提供來源與版本說明,不放原始資料檔。

| 資料集 | 類別 | Train / Test | 原生解析度 | 取得方式 |
|---|---|---|---|---|
| CIFAR-10 | 10 | 50,000 / 10,000 | 32×32 RGB | torchvision 自動下載（**論文預設 backbone**） |
| SVHN | 10 | 73,257 / 26,032 | 32×32 RGB | torchvision 自動下載（`test_32x32.mat`） |
| STL10 | 10 | 5,000 / 8,000 | 96×96 RGB | torchvision 自動下載,降採樣至 32×32 |
| FashionMNIST | 10 | 60,000 / 10,000 | 28×28 灰階 | torchvision 自動下載,複製為 3 通道 |
| CINIC10 | 10 | 90,000 / 90,000 | 32×32 RGB | https://github.com/BayesWatch/cinic-10 （官方 train/test 各 90k,valid 未用） |

全部於訓練時統一調整成 **32×32×3** 輸入。下載與前處理程序見 `05_程式碼/AI_model_train/src/bnn_pynq_train_bitwidth.py` 的 `get_dataloader()`。

官方連結:
- CIFAR-10 https://www.cs.toronto.edu/~kriz/cifar.html
- SVHN http://ufldl.stanford.edu/housenumbers/
- STL-10 https://cs.stanford.edu/~acoates/stl10/
- Fashion-MNIST https://github.com/zalandoresearch/fashion-mnist
- CINIC-10 https://github.com/BayesWatch/cinic-10
