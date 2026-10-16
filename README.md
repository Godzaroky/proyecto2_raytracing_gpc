# Diorama - Ciudad amurallada

Diorama de una ciudad medieval rodeada por una muralla ovalada, renderizado con un raytracer en CPU escrito en Zig con raylib. Toda la escena está hecha con cubos texturizados, cajas rotadas y prismas triangulares.

- **Autor:** Diego Gonzalez - 24170
- **Curso:** Gráficas por Computadora - Universidad del Valle de Guatemala

## Video

https://youtu.be/ZgS2rQLO8e8

## Requisitos

- Zig 0.16.0
- raylib-zig (se descarga solo con `zig build`)

## Ejecutar

```
zig build run -Doptimize=ReleaseFast
```

## Controles

| Control | Acción |
|---|---|
| A / D | Girar alrededor del diorama |
| W / S | Subir / bajar la cámara |
| Rueda del mouse | Acercar / alejar |
| Clic izquierdo + arrastrar | Girar con el mouse |
| Espacio | Activar / desactivar la rotación automática |
| P | Guardar el render actual en `render.png` |
| V | Grabar una vuelta completa en `frames/` para el video |

## Lo que implementa

| Rubro | Implementación |
|---|---|
| Rotación | Cámara orbital alrededor del diorama, con rotación manual y automática (`camera.zig`, `input.zig`) |
| Cámara con zoom | La rueda del mouse cambia la distancia de la órbita, con límites (`input.zig`) |
| Materiales | 9 materiales, cada uno con su propia textura y sus propios valores de albedo, especular, transparencia y reflectividad: arenisca, yeso, tejas, pasto, agua, mármol, adoquín, madera y hojas (`materials.zig`) |
| Refracción | Ley de Snell con reflexión total interna en el agua del canal (`renderer.zig`) |
| Reflexión | Rayos reflejados recursivos en el agua y el mármol, con Fresnel (aproximación de Schlick) |
| Sombras | Rayos de sombra hacia cada luz; los materiales transparentes no bloquean la luz |
| Skybox | Imagen panorámica equirectangular muestreada según la dirección del rayo (`skybox.zig`) |
| Concurrencia | El render se reparte por filas entre todos los núcleos del CPU con un contador atómico (`renderer.zig`) |
| Forma no vista en clase | Prisma triangular para los techos, con intersección rayo-triángulo y rayo-paralelogramo (Möller–Trumbore) (`shapes/prism.zig`, `shapes/face.zig`) |

### Otros detalles técnicos

- **Cajas rotadas** para los segmentos de la muralla: el rayo se lleva al espacio local de la caja (`shapes/rotated_cube.zig`).
- **BVH** (jerarquía de cajas envolventes): cada rayo prueba solo las figuras cercanas, en vez de las ~280 de la escena (`bvh.zig`).
- **Resolución dinámica:** mientras la cámara se mueve se renderiza a un tercio de la resolución y, al detenerse, una vez a resolución completa.
- **Escena generada por código:** la muralla, las calles, el canal, el palacio, las casas y los árboles se construyen en `diorama.zig`.

## Créditos

- Texturas: pixel art de 32×32 generado para este proyecto.
