# seeMoteViewer

seeMote 通用空间配件查看器示例工程。

本工程演示如何在 visionOS 27.0+ 应用中：
- 发现并连接 `GCSpatialAccessory` 空间配件
- 通过 `AccessoryTrackingProvider` 获取配件锚点
- 在混合沉浸空间中显示配件位置、参考模型与数字复制品
- 预览配件提供的 USDZ 参考模型或内置模型

## 运行要求

- Xcode 27.0 beta 或更高版本
- visionOS 27.0 SDK
- Apple Vision Pro 或 visionOS 模拟器

## 首次打开工程

如需详细的操作说明，请参见：https://wiki.dfrobot.com/dfr1285

1. 使用 Xcode 打开 `seeMoteViewer.xcodeproj`。
2. 选中 `seeMoteViewer` target，进入 **Signing & Capabilities**：
   - 将 **Team** 设置为你自己的 Apple Developer Team（或个人免费 Team）。
   - 将 **Bundle Identifier** 改为属于你的唯一标识，例如 `com.yourcompany.seeMoteViewer`。
3. 选择 visionOS 模拟器或连接 Apple Vision Pro 真机，按 `Cmd+R` 运行。

## 工程结构

```
seeMoteViewer/
├── Core/
│   ├── AppState.swift                  # 应用全局状态容器
│   ├── AppConfiguration.swift          # 应用静态配置
│   ├── LocaleManager.swift             # 应用内语言切换
│   ├── AccessoryConnectionManager.swift# 配件连接与断开监听
│   ├── TrackingSessionManager.swift    # ARKit 授权、session 与追踪 provider 生命周期
│   ├── AccessoryTracker.swift          # 视图层统一状态与操作外观
│   ├── PreviewLoader.swift             # 预览模型加载
│   ├── ReplicaPlacementController.swift# 数字复制品放置/清除信号
│   ├── HapticController.swift          # 触觉引擎控制
│   ├── HapticCoordinator.swift         # 触觉控制器生命周期协调
│   └── SceneState.swift                # 沉浸空间状态
├── Reality/
│   ├── EntityFactory.swift             # 实体工厂与可视化占位
│   ├── AnchorManager.swift             # 锚点实体创建与管理
│   └── TrackingMode+Localization.swift # 追踪模式与配件位置的本地化
├── Utilities/
│   ├── Logger+seeMote.swift            # 日志扩展
│   └── CancellableTask.swift           # 可取消任务包装
├── Views/
│   ├── ControlPanelView.swift          # 主控制面板
│   ├── WorldOverlayView.swift          # 混合沉浸空间视图
│   └── ToggleImmersiveSpaceButton.swift# 打开/关闭沉浸空间按钮
├── Resources/
│   ├── model1.usdz                     # 内置预览模型
│   ├── logo.png                        # 应用图标/Logo
│   └── cap-202607152.referenceaccessory# 参考配件文件
├── Localizable.xcstrings               # 中英双语本地化
├── Info.plist                          # 场景配置与参考配件类型声明
└── seeMoteViewer.entitlements          # 沙盒与网络能力
```

## 核心模块说明

- **AccessoryConnectionManager**：监听 `GCSpatialAccessory.spatialAccessories`，管理连接状态并在设备变化时回调。
- **TrackingSessionManager**：运行 `ARKitSession` 并管理 `AccessoryTrackingProvider`，暴露授权状态、追踪状态与最新锚点。
- **AccessoryTracker**：组合连接、追踪、预览加载与复制品控制，作为视图层的单一入口。
- **PreviewLoader**：支持加载配件提供的 `referenceaccessory` 内置 USDZ，或回退到内置 `model1.usdz`。
- **ReplicaPlacementController**：通过 `AsyncStream` 向沉浸空间发送放置/清除数字复制品信号。
- **HapticController / HapticCoordinator**：为已连接配件创建并恢复 `CHHapticEngine`，支持单脉冲与多脉冲模式。
- **WorldOverlayView**：使用 `RealityView` 在混合沉浸空间中渲染锚点标记、参考模型与数字复制品。

## 自定义配件支持

如果你的 seeMote 配件提供自己的 USDZ 预览模型，可在 `PreviewLoader.PreviewModel` 中添加新的枚举 case，并加载对应资源。



## 许可证

本工程由 seeMote 提供，作为面向开发者的参考实现。
