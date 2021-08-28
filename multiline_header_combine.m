let
    Источник = Excel.Workbook(Параметр1, null, true),
    // Берем данные из первого листа Excel без привязки к его имени
    #"Полный отчет_Sheet" = Источник{0}[Data], 
    // Добавлено для устранение бага, когда в разных файлах PQ "видит" разное кол-во столбцов, из-за чего не может их объеденить в одну таблицу
    #"Removed Other Columns4" = Table.SelectColumns(#"Полный отчет_Sheet",{"Column1", "Column2", "Column3", "Column4", "Column5", "Column6", "Column7", "Column8", "Column9", "Column10", "Column11", "Column12", "Column13", "Column14", "Column15", "Column16", "Column17", "Column18", "Column19", "Column20", "Column21", "Column22", "Column23", "Column24", "Column25", "Column26", "Column27", "Column28", "Column29", "Column30", "Column31", "Column32", "Column33", "Column34", "Column35", "Column36", "Column37", "Column38", "Column39", "Column40", "Column41", "Column42", "Column43", "Column44", "Column45", "Column46", "Column47", "Column48", "Column49", "Column50", "Column51", "Column52", "Column53", "Column54", "Column55", "Column56", "Column57", "Column58", "Column59", "Column60", "Column61", "Column62", "Column63", "Column64", "Column65", "Column66", "Column67", "Column68", "Column69", "Column70", "Column71", "Column72", "Column73", "Column74", "Column75", "Column76", "Column77", "Column78", "Column79", "Column80", "Column81", "Column82", "Column83", "Column84", "Column85"}),
    
    // Убираем "шапку" с параметрами, не содержащие нужные данные и выбираем строки заголовка
    #"Removed Top Rows" = Table.Skip(#"Removed Other Columns4",skip_N_first_row+1),
    Select_Rows = Table.Range(#"Removed Other Columns4",skip_N_first_row,header_N_row),

    // Начало алгоритма. Суть идеи заполнить пустые поля заголовка значениями из соседних ячеек
    // Пустые поля образуются из-за объединения ячеек в Excel, когда визуально значение одного поля заголовка
    // растягивается на несколько колонок, хотя хранится в крайней левой ячейке
    // Необходимо продублировать значение объединенной ячейки в правые пустые ячейки, пока не попадется следующая непустая
    // Такой механизм заполнения FillDown работает в Power Query только для строк? поэтому необходимо транспонировать заголовки 
    #"Transposed Table" = Table.Transpose(Select_Rows),

    //Заполняем сперва значения для первого уровня заголовка как основного
    #"Filled Down" = Table.FillDown(#"Transposed Table",{"Column1"}),

    // Далее при заполнении следующих уровней заголовков может происходить неприятная ситуация, когда
    // заголовок "залезает на территорию" другой группы заголовков. Так может происходить, если 
    // в начале новой группы полей будет пустая ячейка. Чтобы этого избежать дальнейшое заполнение
    // будем проводить только в рамках подгрупп, которые разбиваем по первому уровню заголовков
   
    #"Grouped Rows" = Table.Group(#"Filled Down", {"Column1"}, {{"Data", each _, type table [Column1=text, Column2=nullable text, Column3=nullable text, Column4=nullable text]}}),
   
   // теперь заполняем 2й уровень заголовков только в рамках своей подгруппы
    #"Added Custom" = Table.AddColumn(#"Grouped Rows", "Custom", each Table.FillDown([Data],{"Column2"})),
    
    // результат заполненных полей хранится в поле Custom, который надо распрасить в привычную таблицу
    // так как мы при группировке выбрали параметр без группировки, то поле Custom содержить копию таблицы
    #"Removed Other Columns" = Table.SelectColumns(#"Added Custom",{"Custom"}),
    #"Expanded Custom" = Table.ExpandTableColumn(#"Removed Other Columns", "Custom", {"Column1", "Column2", "Column3", "Column4"}, {"Column1", "Column2", "Column3", "Column4"}),
    
    // Повторяем группировку для 3го уровня заголовков, но уже группы определяем по 1му и 2му уровню
    // в текущей версии алгоритма надо вручную прописывать код для каждого нового уровня заголовков
    // т.е если уровней заголовков было больше 3х, то код необходимо было дублировать для каждого нового уровня
    #"Grouped Rows1" = Table.Group(#"Expanded Custom", {"Column1", "Column2"}, {{"Data", each _, type table [Column1=text, Column2=nullable text, Column3=nullable text, Column4=nullable text]}}),
    #"Added Custom1" = Table.AddColumn(#"Grouped Rows1", "Custom", each Table.FillDown([Data],{"Column3"})),
    #"Removed Other Columns1" = Table.SelectColumns(#"Added Custom1",{"Custom"}),
    #"Expanded Custom1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Custom", {"Column1", "Column2", "Column3", "Column4"}, {"Column1", "Column2", "Column3", "Column4"}),
    
    // теперь заполненные заголовки можно объеденить в одну результирующую колонку
    #"Added Custom2" = Table.AddColumn(#"Expanded Custom1", "NewColumnName", each Text.Combine(List.Select(Record.FieldValues(Record.FromList({[Column1],[Column2],[Column3], [Column4]}, type [Column1 = text,Column2 = text,Column3 = text, Column4 = text])), each _<> "" and _ <> null)," & ")),
    #"Removed Other Columns2" = Table.SelectColumns(#"Added Custom2",{"NewColumnName"}),
    
    // возвращаем заголовок к табличному виду
    #"Transposed Table1" = Table.Transpose(#"Removed Other Columns2"),

    // теперь надо объеденить полученный заголовок с исходными данными
    // для этого ссылаемся в функии Combine на шаг, в котором хранятся только данные без заголовка
    Combined_Table_with_Header = Table.Combine({#"Transposed Table1", #"Removed Top Rows" }),
    
    // Завершающий шаг алгоритма, после него реализуется другая логика обработки данных
    #"Promoted Headers" = Table.PromoteHeaders(Combined_Table_with_Header, [PromoteAllScalars=true]),

in
    #"Promoted Headers"