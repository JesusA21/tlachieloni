# Tlachieloni

App para iPhone que superpone imágenes de referencia sobre la cámara en vivo, diseñada para hacer bocetos más rápidos y precisos.

## Funcionalidades

- **Cámara en vivo** a pantalla completa como fondo
- **Seleccionar imagen** de tu galería para superponer
- **Arrastrar** la imagen para posicionarla
- **Pellizcar** (pinch) para cambiar el tamaño
- **Rotar** con dos dedos
- **Slider de opacidad** de 0% a 100%
- **Botón Reset** para volver a la posición original
- **Botón Quitar** para eliminar la imagen superpuesta
- **Modo perspectiva** con 4 esquinas arrastrables para adaptar la imagen a superficies

## Requisitos

- Mac con macOS reciente
- Xcode 15+
- iPhone con iOS 16+
- Cuenta de Apple Developer (gratuita para instalar en tu propio dispositivo, $99/año para publicar en App Store)

## Estructura del proyecto

| Archivo | Función |
|---|---|
| `TlachieloniApp.swift` | Punto de entrada de la app |
| `CameraView.swift` | Feed en vivo de la cámara trasera usando AVFoundation |
| `ImagePicker.swift` | Selector de imágenes del álbum de fotos |
| `ContentView.swift` | Vista principal con imagen superpuesta y controles |
| `PerspectiveOverlay.swift` | Modo perspectiva con 4 esquinas arrastrables |
| `Info.plist` | Permiso de cámara |

## Cómo abrir y correr

1. Abre Xcode
2. `File > Open` → navega a `~/Code/Tlachieloni/Tlachieloni.xcodeproj`
3. Conecta tu iPhone por USB
4. Selecciona tu dispositivo como destino (la cámara no funciona en el simulador)
5. Presiona ▶️ Run

> La primera vez Xcode te pedirá configurar tu equipo de desarrollo en **Signing & Capabilities**. Si usas tu Apple ID personal gratuito, selecciónalo ahí y Xcode firmará la app automáticamente para tu dispositivo.

## Tecnologías

- Swift 5
- SwiftUI
- AVFoundation (cámara)
- PhotosUI (selector de imágenes)
