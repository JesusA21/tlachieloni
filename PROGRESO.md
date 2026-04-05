# Tlachieloni — Progreso del Proyecto

## Estado general: 🟡 En desarrollo

---

## Funcionalidades core

- [x] Feed de cámara en vivo (CameraView)
- [x] Selector de imágenes del álbum (ImagePicker)
- [x] Superponer imagen sobre la cámara
- [x] Arrastrar imagen (posición)
- [x] Pellizcar para escalar (tamaño)
- [x] Rotar con dos dedos
- [x] Slider de opacidad
- [x] Botón reset (restaurar transformaciones)
- [x] Botón quitar imagen
- [ ] Probar en dispositivo físico

## Mejoras pendientes (por prioridad)

1. [x] Bloquear imagen en posición (toggle 🔒 para evitar moverla por accidente)
2. [x] Modo pantalla limpia (ocultar controles para dibujar sin estorbos)
3. [x] Invertir/voltear imagen (espejo horizontal/vertical)
4. [ ] Guardar captura de pantalla (cámara + overlay)
5. [ ] Múltiples imágenes superpuestas
6. [ ] Historial de imágenes recientes
7. [ ] Ajuste de perspectiva por esquinas (perspective warp para adaptar imagen a superficies)

## Deuda técnica

- [ ] **CameraView: AVCaptureSession sin referencia persistente** — En `CameraView.swift`, el `AVCaptureSession` se crea dentro de `makeUIView` sin guardarse como referencia (por ejemplo en un `Coordinator`). Esto funciona, pero si SwiftUI recrea la vista podrían crearse sesiones duplicadas. Refactorizar para que la sesión viva en el Coordinator y se reutilice.

## Configuración del proyecto

- [x] Estructura de archivos Swift
- [x] Proyecto Xcode (.xcodeproj)
- [x] Info.plist con permiso de cámara
- [x] Assets catalog
- [ ] Ícono de la app
- [ ] Configurar signing con Apple ID
- [ ] Launch screen personalizada
- [x] Resolver deuda técnica de CameraView

## Documentación

- [x] README.md
- [x] PROGRESO.md

---

## Registro de cambios

### v0.2 — Mejoras de UX
- Bloqueo de imagen (toggle 🔒) para evitar moverla por accidente
- Modo pantalla limpia (botón 👁 arriba a la derecha para ocultar/mostrar controles)
- Invertir/voltear imagen (espejo horizontal y vertical)

### v0.1 — Versión inicial
- Creación del proyecto con estructura base
- Cámara en vivo con AVFoundation
- Overlay de imagen con gestos (drag, pinch, rotate)
- Controles de opacidad y reset
- Selector de imágenes con PHPicker
