# Blueprint: Aplicación de Anotación de Imágenes - LabelLab

Este documento sirve como la única fuente de verdad para el desarrollo de la aplicación de anotación de imágenes "LabelLab". Describe el propósito, las características, el diseño y el plan de acción actual del proyecto.

## 1. Visión General

LabelLab es una aplicación de escritorio y móvil construida con Flutter, diseñada para simplificar y acelerar el proceso de etiquetado de imágenes para modelos de Computer Vision. La aplicación permite a los usuarios importar imágenes, definir clases y dibujar cuadros delimitadores (`bounding boxes`) sobre objetos, para finalmente exportar las anotaciones en formatos estándar como YOLO.

## 2. Arquitectura y Diseño

- **Framework:** Flutter
- **Lenguaje:** Dart
- **Almacenamiento:** El proyecto y las imágenes se gestionan directamente en el sistema de archivos local del usuario, promoviendo la privacidad y el control total de los datos.
- **Interfaz:** La aplicación sigue los principios de Material Design, buscando una experiencia de usuario limpia, intuitiva y eficiente.

## 3. Características Implementadas (Fase 1 - Concluida)

- **Creación de Proyectos:** Los usuarios pueden crear un nuevo proyecto especificando un nombre y una ubicación en el sistema de archivos.
- **Gestión de Imágenes:**
  - **Importación Múltiple:** Permite añadir imágenes desde archivos individuales o carpetas enteras.
  - **Procesamiento de Imágenes:** Las imágenes importadas se redimensionan a un ancho estándar (640px) para optimizar el rendimiento y el almacenamiento.
  - **Visualización:** Las imágenes se muestran en una cuadrícula (`GridView`) en la pantalla del proyecto, con indicadores visuales para mostrar si ya han sido anotadas.
- **Gestión de Clases:** Los usuarios pueden definir y editar una lista de clases (etiquetas) para cada proyecto.
- **Anotación de Imágenes:**
  - **Interfaz de Anotación Robusta:** Una pantalla dedicada permite a los usuarios dibujar, seleccionar, mover y redimensionar cuadros delimitadores.
  - **Interacción Fluida en Tiempo Real:** Las transformaciones (mover, redimensionar) de las cajas se reflejan instantáneamente, siguiendo el gesto del usuario para una experiencia natural.
  - **Asignación de Clases y Colores:** Cada cuadro delimitador se asocia con una clase y se muestra con un color distintivo.
- **Funcionalidad de Deshacer y Rehacer (Undo/Redo):**
    - Un sistema de historial de estados robusto y centralizado permite revertir y restaurar de forma fiable todas las acciones de anotación.
- **Optimización de Rendimiento:**
    - El lienzo de dibujo utiliza una técnica de `RepaintBoundary` y `CustomPainter` de dos capas para separar el renderizado de la imagen estática de las anotaciones dinámicas, garantizando una alta fluidez incluso con imágenes grandes.
- **Exportación de Proyectos:**
  - **Formato YOLO:** Los proyectos se pueden exportar como un archivo ZIP que contiene las imágenes, los archivos de texto de anotación en formato YOLO, y un archivo `classes.txt`.
  - **Función de Compartir:** Se utiliza el paquete `share_plus` para permitir al usuario compartir el archivo ZIP exportado.

---

## 4. Línea de Acción Actual: Fase 2 - Refinamiento y Experiencia de Usuario

**Objetivo:** Transformar la aplicación de una herramienta funcional a una experiencia de usuario pulida, intuitiva y agradable.

**Estado Actual:** La funcionalidad principal de la aplicación está completa, es estable y tiene un rendimiento óptimo.

**Próximos Pasos:**

1.  **Pulido Visual y de Interfaz (UI Polish):**
    - **Mejorar Iconos:** Reemplazar los botones de texto de la barra de acciones (Deshacer, Rehacer, Guardar) por iconos de Material Design claros y reconocibles.
    - **Optimizar Selección de Clase:** Sustituir la lista actual de `ElevatedButton` para las clases por un control más elegante y escalable, como un `DropdownButton` o una lista de `Chips` seleccionables.
    - **Estética General:** Revisar espaciados, colores y tipografía para asegurar una presentación visualmente equilibrada y profesional.

2.  **Guía de Inicio Rápido (Onboarding):**
    - **Implementar un Mini-Tutorial:** Al abrir la pantalla de anotación por primera vez en un proyecto, se mostrará una superposición o un diálogo simple.
    - **Contenido del Tutorial:** Explicará las tres interacciones básicas de forma gráfica y concisa:
        - "Arrastra en un área vacía para **Dibujar** una nueva caja."
        - "Arrastra una caja o sus bordes para **Moverla** o **Redimensionarla**."
        - "Toca una caja para **Seleccionarla** y toca el icono de la papelera para **Eliminarla**."

**¿En qué debería trabajar ahora?**
