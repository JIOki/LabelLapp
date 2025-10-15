# Blueprint: Aplicación de Anotación de Imágenes - LabelLab

Este documento sirve como la única fuente de verdad para el desarrollo de la aplicación de anotación de imágenes "LabelLab". Describe el propósito, las características, el diseño y el plan de acción actual del proyecto.

## 1. Visión General

LabelLab es una aplicación de escritorio y móvil construida con Flutter, diseñada para simplificar y acelerar el proceso de etiquetado de imágenes para modelos de Computer Vision. La aplicación permite a los usuarios importar imágenes, definir clases y dibujar cuadros delimitadores (`bounding boxes`) sobre objetos, para finalmente exportar las anotaciones en formatos estándar como YOLO.

## 2. Arquitectura y Diseño

- **Framework:** Flutter
- **Lenguaje:** Dart
- **Almacenamiento:** El proyecto y las imágenes se gestionan directamente en el sistema de archivos local del usuario, promoviendo la privacidad y el control total de los datos.
- **Interfaz:** La aplicación sigue los principios de Material Design, buscando una experiencia de usuario limpia, intuitiva y eficiente.

## 3. Características y Flujo de Trabajo

### Características Implementadas

- **Creación de Proyectos:** Los usuarios pueden crear un nuevo proyecto especificando un nombre y una ubicación en el sistema de archivos.
- **Gestión de Imágenes:**
  - **Importación Múltiple:** Permite añadir imágenes desde archivos individuales o carpetas enteras.
  - **Procesamiento de Imágenes:** Las imágenes importadas se redimensionan a un ancho estándar (640px) para optimizar el rendimiento y el almacenamiento.
  - **Visualización:** Las imágenes se muestran en una cuadrícula (`GridView`) en la pantalla del proyecto, con indicadores visuales para mostrar si ya han sido anotadas.
- **Gestión de Clases:** Los usuarios pueden definir y editar una lista de clases (etiquetas) para cada proyecto.
- **Anotación de Imágenes:**
  - **Interfaz de Anotación Avanzada:** Una pantalla dedicada permite a los usuarios dibujar, seleccionar, mover, redimensionar y eliminar cuadros delimitadores.
  - **Asignación de Clases y Colores:** Cada cuadro delimitador se asocia con una clase y se muestra con un color distintivo, mejorando la claridad visual.
- **Exportación de Proyectos:**
  - **Formato YOLO:** Los proyectos se pueden exportar como un archivo ZIP que contiene las imágenes, los archivos de texto de anotación en formato YOLO, y un archivo `classes.txt`.
  - **Función de Compartir:** Se utiliza el paquete `share_plus` para permitir al usuario compartir el archivo ZIP exportado a través de las aplicaciones nativas del sistema operativo.

### Última Tarea Completada: Refactorización y Mejoras de Usabilidad

Se ha completado una importante línea de acción para mejorar la usabilidad y la robustez de la herramienta de anotación. Las mejoras clave incluyen:

- **Habilitada la Selección de Cajas:** Un toque del usuario sobre una caja existente la marca como seleccionada, mostrando un borde realzado.
- **Implementada Eliminación y Redimensionamiento:** Las cajas seleccionadas ahora muestran un icono de eliminación y tiradores en las esquinas para un ajuste intuitivo.
- **Asegurada la Calidad de los Datos:** Se implementó una lógica de "pinza" (clamp) para asegurar que ninguna caja pueda exceder los bordes de la imagen.
- **Mejorada la Claridad Visual:** Las cajas ahora se dibujan con un color único asignado a cada clase.
- **Limpieza de Código Exhaustiva:** Se identificó y corrigió un error de sintaxis que generaba más de 100 problemas en el analizador de Dart. El código base se ha limpiado de todas las advertencias y errores, alcanzando un estado de "cero problemas".

---

## 4. Línea de Acción Actual: Deshacer y Rehacer

Basado en el feedback del usuario, la prioridad actual es implementar una funcionalidad robusta de deshacer/rehacer para mejorar la experiencia de edición.

**Paso 1: Implementar Deshacer/Rehacer (Undo/Redo)**
-   **Acción:** Integrar un sistema de historial de estados en la pantalla de anotación (`DrawingCanvas`). Cada acción que modifica los cuadros delimitadores (crear, mover, redimensionar, eliminar) se registrará.
-   **Meta:** Permitir a los usuarios revertir y restaurar acciones fácilmente usando botones de "Deshacer" y "Rehacer", minimizando la frustración por errores accidentales.
-   **Consideraciones:** Se añadirá una barra de acciones en la interfaz de anotación con los botones correspondientes. Se gestionará el estado para habilitar o deshabilitar los botones cuando no haya más acciones que deshacer o rehacer.

## 5. Próximos Pasos: Funcionalidad Avanzada

Una vez implementada la funcionalidad de deshacer/rehacer, se continuará con las siguientes características:

**Paso 2: Implementar Zoom y Desplazamiento (Pan)**
-   **Acción:** Integrar la funcionalidad de zoom y pan en el `DrawingCanvas` para permitir a los usuarios navegar por imágenes grandes y realizar anotaciones precisas en objetos pequeños.
-   **Meta:** Mejorar drásticamente la precisión y la comodidad del proceso de anotación.
-   **Consideraciones:** Se utilizarán gestos estándar (pellizcar para hacer zoom, arrastrar para desplazar). Se debe asegurar que las coordenadas de los cuadros delimitadores se mapeen correctamente independientemente del nivel de zoom y la posición de la vista.
