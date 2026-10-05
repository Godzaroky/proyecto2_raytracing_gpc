# Diorama - Raytracer

Diorama de una ciudad amurallada (Shinganshina de AOT) renderizada con un raytracer en CPU, escrito en Zig con raylib.

## Requisitos

- Zig 0.16.0
- raylib-zig (se descarga solo con `zig build`)

## Ejecutar

```
zig build run -Doptimize=ReleaseFast
```

## Controles

| Tecla | Acción |
|---|---|
| P | Guarda el render actual en `render.png` |
