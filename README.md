# Blueprint Book Shelf

Factorio 2.1.23+. Standalone mod; Space Age is optional.

## Использование

1. Нажмите **Ctrl+Shift+B** или кнопку с книгой в верхнем левом углу.
2. Откройте обычный инвентарь и возьмите чертёж или книгу в руку. Панель не закрывает инвентарь.
3. Наведите курсор на строку целевой книги **в панели мода**.
4. Нажмите левый или правый **Shift**. Предмет переместится внутрь этой книги.

Панель показывает книги из основного инвентаря, включая вложенные. Для одинаковых названий отображается путь к книге; число в скобках — количество предметов непосредственно в ней. Поиск работает по названиям и пути; латиница без учёта регистра, кириллица с учётом. При изменении инвентаря или предмета в руке список обновляется автоматически. Есть кнопка «Обновить» для изменений, сделанных другими модами.

Клавиши меняются в **Настройки → Управление → Моды**. Можно заменить Shift на Ctrl, Alt или сочетание. Для переноса нужно именно нажать клавишу после наведения. Панель перетаскивается за заголовок; закрывается крестиком, верхней кнопкой или Ctrl+Shift+B.

Работает с книгами-предметами из вашего инвентаря. Стандартная библиотека чертежей не является инвентарём; ссылку из неё сначала нужно превратить в предмет. Наведение на книгу в стандартном инвентаре не обрабатывается.

Предметы перемещаются целиком с сохранением настроек и вложенных книг. Проверяется актуальная принадлежность целевой книги вашему инвентарю. Перенос книги в саму себя или своего потомка запрещён; заполненная книга не перезаписывается.

## Installation / English

Copy `BlueprintBookShelf_1.0.0.zip` to `%APPDATA%\Factorio\mods`, restart Factorio and enable the mod. Install the ZIP **or** the source folder, not both.

Open the shelf with **Ctrl+Shift+B** or the top-left book button. Pick up an inventory blueprint or book, hover over the destination row **inside the shelf panel**, and press either **Shift** key. The normal inventory remains usable while the shelf is open. Rebind either action under **Settings → Controls → Mods**.

The shelf lists main-inventory books and their descendants, with parent paths and direct item counts. Search filters names/paths (ASCII case-insensitive; other text uses exact case). The list updates on inventory/cursor changes; Refresh also picks up changes made by other mods. Only physical inventory items are supported; blueprint-library references must first become inventory items.

Open Book Inserter may be installed alongside this mod. Their Shift actions resolve different targets.

## Source code

[GitHub repository](https://github.com/Tsyklop/blueprint-book-shelf)
