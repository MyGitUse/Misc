library(shiny)
library(tidyverse)
library(readxl) #read excel
library(DT) #manipulate datatables
library(shinyjs)
library(shinyWidgets)
library(xlsx)

#library(glue)
#library(shinydashboard)
#library(sodium)
#library(shinyFiles)

#UI########################################################

ui <- fluidPage(
  theme=shinythemes::shinytheme("flatly"), #select a theme
  useShinyjs(),  #Make sure to have this in UI to be able to use show/hide functions as well as button enable/disable
  titlePanel(h1(strong("Nelson's First ShinyApp"))),
  #navbarPage( #looks nice but screws up app for some reason, so disabled
  tabsetPanel(
    tabPanel(title="Instructions",  #Note: this structuring allows me to put text & a picture in a single sidebarpanel
        sidebarPanel(width=12, #full 12 width (not necessary to mention argument but just a reminder for the future)
            sidebarLayout(
              mainPanel(width=6,
                htmlOutput("InstructionsText")), #Instructions text
              mainPanel(width=6,
                htmlOutput("HTMLimg"))
                        )
                    )
             ),
    tabPanel(title="Table Editor", #set tab for main app
             sidebarLayout( #this makes a box around below outputs
               #The Page Title
               
               #The Upload Button (eval 1)
               sidebarPanel(width=4,
                            fileInput("UploadID", label="Upload Excel Speadsheet", buttonLabel="Upload", accept=c(".xlsx"), multiple=F),
                            selectInput("SelectSheet", "Which Sheet Would You Like to View?", choices=NULL),
                            #Select rows to use as column names (eval 3 & 4)
                            uiOutput("ColNameNdel"),
                            #Display Warning messages for eval 3
                            verbatimTextOutput("WarningMsg"),
                            #Display Selection message for eval 3
                            verbatimTextOutput("SelectionMsg"),
                            #Select rows to drop (eval 4)
                            uiOutput("RowsDelete"),
                            #Display Warning messages for eval 4
                            verbatimTextOutput("WarningMsg2"),
                            #Display Selection message for eval 4
                            verbatimTextOutput("SelectionMsg2"),
                            #Select to delete more rows or not (eval 5)
                            uiOutput("AdditionalRowDel"),
                            #Select to delete more rows or not "YES" (eval 5)
                            uiOutput("AdditionalRowDelYES"),
                            #If selection is "YES" - render out naming + save buttons (eval 5)
                            uiOutput("cachetable"),
                            #Row deletion message per state 
                            verbatimTextOutput("eval5msg1"), #Row #deletion message associated w/ "AddRowsDelTableSAVE1"
                            tags$head(tags$style("#eval5msg1{color:red; font-size:12px; font-style:bold;
overflow-y:scroll; max-height: 500px; background: ghostwhite;}")),
                            verbatimTextOutput("eval5msg2"),
                            tags$head(tags$style("#eval5msg2{color:red; font-size:12px; font-style:bold;
overflow-y:scroll; max-height: 500px; background: ghostwhite;}")),
                            verbatimTextOutput("eval5msg3"),
                            tags$head(tags$style("#eval5msg3{color:red; font-size:12px; font-style:bold;
overflow-y:scroll; max-height: 500px; background: ghostwhite;}")), 
                            #make a sidebar panel inside a sidebar panel for saved states downloading/viewing
                            #add a rendered text?
                            uiOutput("loadsave0"),   #unmodified table = state0
                            uiOutput("loadsave1"),
                            uiOutput("loadsave2"),
                            uiOutput("loadsave3")
               ),
               mainPanel(width=8,
                         #The sheet tables
                         #(eval 2)
                         DTOutput("UploadedTable"),  #Unmodified table - note using width=9 for all 3 when total should be 12 b/c prior tables get hidden
                         #(eval 3)
                         DTOutput("RenamedTable"),    #Modified header table
                         #(eval 4)
                         DTOutput("RowsDelTable"),    #Modified rows table
                         #(eval 5 "YES")
                         DTOutput("AddRowsDelTable"), #Additional Modified rows table
                         DTOutput("AddRowsDelTableSAVE1"), #Need to save each saved state table for new render
                         DTOutput("AddRowsDelTableSAVE2"), #Need to save each saved state table for new render
                         DTOutput("AddRowsDelTableSAVE3"), #Need to save each saved state table for new render
                         #(eval 5 "NO")
                         DTOutput("AddRowsDelTableSAVENO") #Need to save "NO" choice state table for new render for table mods
               )
             )),
    tabPanel(title="96-Well Plotting (WIP)", #set 96well plot
             tabsetPanel(
               tabPanel("Interactive Plate",
                        sidebarPanel(width=12, align="center",
                                     fluidRow(
                                       column(width=6,
                                              fileInput("UploadIDplot", label="Upload Excel Speadsheet", buttonLabel="Upload", accept=c(".xlsx"), multiple=F)),
                                       column(width=6,
                                              selectInput("SelectSheetplot", "Which Sheet Would You Like to View?", choices=NULL))
                                     ),
                                     fluidRow(align="center",
                                              conditionalPanel(condition="output.import_ready",
                                                               verbatimTextOutput("LookAtTabMsg")), #Tell user to look at uploaded table tab & make selections
                                              tags$head(tags$style("#LookAtTabMsg{color:black; font-size:20px; font-style:bold;
overflow-y:scroll; max-height: 500px; background: ghostwhite;}"))
                                     ),
                                     fluidRow(
                                       column(width=4,
                                              numericInput("ConcSelect", "Which Cells Contain Concentration Values?", value=NULL)), #not req can input 0
                                       column(width=4,
                                              numericInput("VolSelect", "Which Cells Contain Volume Values?", value=NULL)), #not req can input 0
                                       column(width=4,
                                              numericInput("CommentSelect", "Which Cells Contain Comments?", value=NULL)) #not req can input 0
                                     ),
                                     fluidRow(
                                       actionButton("GenerateBtn", "Click to Generate Your 96-Well Plate!")
                                     )
                        ),
                        fluidRow(
                          column(5,
                                 DTOutput("SelectionTable") #shows user selections)
                          ),
                          column(5, align="center",
                                 plotOutput("InteractivePlot", click="click")
                          ),
                          column(5, align="center",
                                 verbatimTextOutput("InteractivePlotMsg"), #interactive text per plot click
                                 tableOutput("TTT")
                          )
                        )
               ),
               tabPanel("Uploaded Table",
                        fluidRow(align="center",
                                 actionButton("AddColsBtn", "Add Column(s)"), #Buttons to add row/column -> skipping add columns (see server side notes)
                                 actionButton("AddRowsBtn", "Add Row(s)"),
                                 textOutput("HighlightCellsMsg")
                        ),
                        fluidRow(align="center",
                                 DTOutput("ULtable") #uploaded table
                        )
               ),
               tabPanel("Example Table (Preferred Formatting)",
                        fluidRow(align="center",
                                 textOutput("RowExTXT"),
                                 tableOutput("EXtab1")  
                        ),
                        fluidRow(align="center",
                                 htmlOutput("ColExTXT"),
                                 tableOutput("EXtab2")  
                        )
               )
             ),
             verbatimTextOutput("test") #used for debugging
             )
  )
  #)
)
#SERVER#########################################################  


server <- function(input, output, session) {
  
  ##############TABLE SECTION##########################
  #The Upload Button
  #Upload all sheets in excel file (eval 1)
  Upload <- eventReactive(req(input$UploadID), {    #get $datapath for reading in excel sheet
    TabNameList <- readxl::excel_sheets(input$UploadID$datapath) #Get sheet names individually
    list(TabNameList=TabNameList) # NOTE TO RECALL VARIABLES IN FUNCTION(Upload) -> MUST PLACE VARIABLES AS A LIST
  })
  
  #Update choices in SelectInput to reflect sheets uploaded
  observe({updateSelectInput(session, "SelectSheet", choices=Upload()$TabNameList)}) #Only works w/ observe b/c updates per single change == Re-fresh/Reset functionality
  
  #The sheet tables
  #Save read-in spreadsheet for downstream dynamic changes via reactive() (eval 2)
  table <- eventReactive(input$SelectSheet, {
    show("UploadedTable") #This shows unmodified table per sheet selection -NOTE NEED TO ADD THIS BECAUSE MODIFIED TABLE BELOW (tableNew()) WILL HIDE UNMODIFIED TABLE (table()) & IF WANTED TO SELECT NEW SHEET NEED TO UNHIDE
    hide("WarningMsg")
    hide("RowsDelete") #Hide eval3 = delete rows, everytime a new unmodified sheet is selected
    show("RenamedTable")  #show renamed table from eval3 --Needed b/c if eval4 to re-start, this will re-show eval3 table for reassessment
    hide("RowsDelTable") #Hide all other tables
    hide("AddRowsDelTable") 
    hide("AddRowsDelTableSAVE1")
    hide("AddRowsDelTableSAVE2")
    hide("AddRowsDelTableSAVE3")
    hide("AddRowsDelTableSAVENO")
    shinyjs::enable("selectHeaderBtn") #enable eval3 button per sheet select = reset
    shinyjs::enable("deleteRowsBtn") #enable eval4 button per sheet select = reset
    shinyjs::disable("AddRowDelBtnConf") #disble eval5 button "delete these rows" for sheet reselect
    shinyjs::disable("DeselRows") #disble eval5 button "delete these rows" for sheet reselect
    shinyjs::disable("SaveTbl") #disble eval5 button "delete these rows" for sheet reselect
    if (!is.null(input$UploadID) && #If uploadID (upload file is not NULL) &
        (input$SelectSheet %in% Upload()$TabNameList)) { #If Selected sheet from dropdown == in list of sheet names
      return(read_excel(input$UploadID$datapath, sheet = input$SelectSheet, col_names=F)) #If above is true, then read excel based upon selected sheet
    } else {
      return(NULL)
    }
  })
  
  
  #plot (eval 2)
  output$UploadedTable <- renderDT(table(), options = list("pageLength" = 50)) #show first 50 rows of dataframe 
  
  #extract max row# from table generated (eval 2)
  RowMax <- reactive({    #Reactive to change per sheet selected
    Rmax <- nrow(table()) #get max row from table
    list(Rmax=Rmax) #list to allow call in further functions
  })
  
  
  #Select rows to drop & Column names
  #Add UI side
  output$ColNameNdel <- renderUI({
    #Select row to become header (eval 3)   
    conditionalPanel(condition="input.SelectSheet != ''", #conditionalPanel() allows hidden input/output until condition met -Note input.ID not input$ID, also note '' = NULL
                     fluidRow(
                       column(8,
                              numericInput(
                                "HeaderRow",
                                "Select Row to Make Header (No Header=0)",
                                value=NULL, min=0, max=req(RowMax()$Rmax))),  #error starts here b/c RowMax() not evaluated yet -- used req() to prevent error
                       column(4, style = "margin-top: 25px;", #style= aligns button with numericInput
                              actionButton("selectHeaderBtn", "Make Header", icon = icon("location-arrow")))
                     ))
  })
  #Select rows to delete (eval 4)
  output$RowsDelete <- renderUI({
    conditionalPanel(condition="output.SelectionMsg", #Condition = Pops up once output$selectionMsg is evaluated -NOTE: this is the limiting step & reason why disable() is used on buttons after 1 click (for future reference)
                     fluidRow(
                       column(8,
                              numericRangeInput(
                                "DeleteRows",
                                "Select Range of Rows to Drop (0 to 0 = None):",
                                value=c(1,RowMax()$Rmax))),
                       column(4, style = "margin-top: 25px;", #style= aligns button with numericInput
                              actionButton("deleteRowsBtn", "Delete Rows", icon = icon("trash-o")))
                     ))                   
  })
  #Server Side of select rows
  #Select row to become header
  #extract header names (eval 3)
  HeadN <- eventReactive(  #Use eventReactive() not reactive() if want change per button click
    req(input$selectHeaderBtn),{ #requires button to be pressed first
      TabNames <- table()[input$HeaderRow,] #all column values in row#
      list(TabNames=TabNames) #list to allow call in further functions
    })
  #Change header values (eval 3)
  #When header selected
  tableNew <- eventReactive(req(input$selectHeaderBtn), { #eventReactive() makes it so per button click = change
    if(!is.null(input$HeaderRow) && input$HeaderRow>=1 && input$HeaderRow<=RowMax()$Rmax){ #Check if statifies min/max of #rows
      TableRename <- table() #Assign old table to new variable
      hide("UploadedTable")  #Hide existing table
      show("RenamedTable")  #show renamed table
      colnames(TableRename) <- HeadN()$TabNames #Make column names of modified table = selected row#
      hide("WarningMsg") #Hide warning message when in range
      output$SelectionMsg <- renderText(paste(Sys.time(), ": Selected row#", isolate(input$HeaderRow), " as header" , "\n\t\t for sheet: ", isolate(input$SelectSheet), "\n\t\t of file: ", basename(isolate(input$UploadID$name)), sep="")) #isolate() stops input$HeaderRow text from changing when the number changes without button click (basename(input$UploadID$name) grabs the name of the upload file)
      show("RowsDelete") #Show eval3 (row delete) after eval2 (row rename) is evaluated
      shinyjs::disable("selectHeaderBtn") #disable button after use
      return(TableRename) #return the renamed table as assignment to tableNew() variable
    }else if(!is.null(input$HeaderRow) && input$HeaderRow==0){ #If 0 selected = no header (basically same as above but no header names assigned)
      TableRename <- table()
      hide("UploadedTable")
      show("RenamedTable")
      hide("WarningMsg")
      output$SelectionMsg <- renderText(paste(Sys.time(), ": No row selected as header", "\n\t\t for sheet: ", isolate(input$SelectSheet), "\n\t\t of file: ", basename(isolate(input$UploadID$name)), sep=""))
      show("RowsDelete")
      shinyjs::disable("selectHeaderBtn") 
      return(TableRename) #Just return original table as modified table
    }else{   #If not, then spit out a warning message
      show("WarningMsg") #Show warning message when out of range
      hide("RowsDelete")
      output$WarningMsg <- renderText("WARNING: Out of Range")
    }})
  #Render modified table
  output$RenamedTable <- renderDT(tableNew(), options = list("pageLength" = 50))  #show first 50 rows of dataframe)
  #Select rows to delete (eval 4)
  tableNewDel <- eventReactive(req(input$deleteRowsBtn), { #must be eventReactive to constantly update sheet, instead of observeEvent (which only occurs once)
    if(!is.null(input$DeleteRows) && input$DeleteRows[1]>=1 && input$DeleteRows[2]<=RowMax()$Rmax){ #Check if statifies min/max of #rows
      TableDel <- tableNew() #Assign old table to new variable
      TableDel <- TableDel[-c(input$DeleteRows[1]:input$DeleteRows[2]),] #Make column names of modified table = selected row#
      return(TableDel) #return the renamed table as assignment to tableNew() variable
    }else if(!is.null(input$DeleteRows) && input$DeleteRows[1]==0 && input$DeleteRows[2]==0){ #If 0 selected = no header (basically same as above but no header names assigned)
      TableDel <- tableNew()
      return(TableDel) #Just return original table as modified table
    }else{   #If not, then spit out a warning message
    }
  })
  
  #separated deleteRowsBtn click events into eventReactive (for calculations) & observeEvent(for messages) b/c this somehow helps prevent re-calculations above when sheet is re-freshed via SelectSheet
    # Note- I needed to use eventReactive for calculations + assign a env-variable tableNewDel() for downstream processing (can't assign env-var with observeEvent)
  observeEvent(req(input$deleteRowsBtn), { 
    if(!is.null(input$DeleteRows) && input$DeleteRows[1]>=1 && input$DeleteRows[2]<=RowMax()$Rmax){ #Check if statifies min/max of #rows
    show("SelectionMsg2") #see else statement of this function for reason why this exists
    hide("RenamedTable")  #Hide existing table
    show("RowsDelTable")  #show row deleted table
    hide("WarningMsg2") #Hide warning message when in range
    output$SelectionMsg2 <- renderText(paste(Sys.time(), ": Selected rows#", isolate(input$DeleteRows[1]), " to ",  isolate(input$DeleteRows[2]), " for deletion" , "\n\t\t for sheet: ", isolate(input$SelectSheet), "\n\t\t of file: ", basename(isolate(input$UploadID$name)), sep="")) #isolate() stops input$HeaderRow text from changing when the number changes without button click
    show("RowsDelete") #Show eval3 (row delete) after eval2 (row rename) is evaluated
    shinyjs::disable("deleteRowsBtn") #disable button after use
    shinyjs::enable("AddRowDelBtn") #enable confirm button eval5 for Re-selected page
  }else if(!is.null(input$DeleteRows) && input$DeleteRows[1]==0 && input$DeleteRows[2]==0){ #If 0 selected = no header (basically same as above but no header names assigned)
    show("SelectionMsg2")
    hide("RenamedTable")
    show("RowsDelTable")
    hide("WarningMsg2")
    shinyjs::disable("deleteRowsBtn") 
    output$SelectionMsg2 <- renderText(paste(Sys.time(), ": No rows selected for deletion", "\n\t\t", " for sheet: ", isolate(input$SelectSheet), sep=""))
    show("RowsDelete")
    shinyjs::enable("AddRowDelBtn") #enable confirm button eval5 for Re-selected page
  }else{   #If not, then spit out a warning message
    show("WarningMsg2") #Show warning message when out of range
    hide("SelectionMsg2") #Needed b/c user may be confused w/ both selectionmsg2 + warningmsg2 (not required, if remove then also remove show('selectionmsg2'))
    output$WarningMsg2 <- renderText("WARNING: Out of Range")
  }
})
    
  #Render modified table
  output$RowsDelTable <- renderDT(tableNewDel(), options = list("pageLength" = 50))  #show first 50 rows of dataframe)
  
  # Select to delete additional rows or not
  #Add UI side
  output$AdditionalRowDel<- renderUI({
    #Select to delete more rows or not (eval 5)   
    conditionalPanel(condition="output.SelectionMsg2", #Condition = Pops up once output$selectionMsg2 is evaluated -NOTE: this is the limiting step & reason why disable() is used on buttons after 1 click (for future reference)
                     fluidRow(
                       column(8,
                              selectInput(
                                "ChoiceRowDel",
                                "Select More Rows to Delete?",
                                choices=c("Yes", "No"),
                                selected=NULL)),
                       column(4, style = "margin-top: 25px;",
                              actionButton("AddRowDelBtn", "Confirm", icon = icon("thumbs-o-up")))
                     ))
  })
  #Server Side of select additional rows (eval 5)
  #Add selection of yes or no - delete extra rows
  #######################CONDITION YES BELOW###########################
  #If selection is "Yes"
  #Allow user to manually click rows to delete
  observeEvent(req(input$AddRowDelBtn), { #using observeEvent b/c don't need continously updating env-variable (ie) each highlight=update==eventReactive vs each highlight+click=update==observeEvent)
      shinyjs::disable("AddRowDelBtn") #disable button after use (for both "Yes" & "No" choices)
      shinyjs::enable("SaveTbl") #enable save button during re-select sheet (Note- early enable b/c no observeEvent I can throw it in below)
      if(input$ChoiceRowDel == "Yes"){
      output$AdditionalRowDelYES<- renderUI({  #Make UI appear to show message of selecting rows & text box reactively showing row selection
        fluidRow(
          htmlOutput("SelectRowsMsg"), #Note use htmlOutput instead of TextOutput to use html tags
          verbatimTextOutput("ShowRowsSelected"),
          fluidRow(
            column(6,
                   actionButton("AddRowDelBtnConf", "Delete These Rows", class = "btn-danger", icon = icon("bomb"))), #bootstrap class buttons (HTML)
            column(6,
                   actionButton('DeselRows', 'Deselect All Rows', class = "btn btn-info", icon = icon("times-circle-o"))),
            verbatimTextOutput("eval5msg"),
            tags$head(tags$style("#eval5msg{color:red; font-size:12px; font-style:bold;
overflow-y:scroll; max-height: 500px; max-width: 600px; background: ghostwhite;}")), #Code I took from somewhere, basically prevents horizontal stroll, adds text colour + vertical scroll (overflow-x:hidden;) [I'm using the red to highlight deleted rows]-> Can remove (not necessary)
            align="center"))})
      output$SelectRowsMsg <- renderText(paste("<b>Click On Rows of Table to Delete (Hold Shift For Range Select)</b>", "<br>", "<c><u>You Have Selected These Rows For Deletion</u></c>")) #start server function for above UI
      output$ShowRowsSelected <- renderPrint({list(SelectedRows = sort(input$RowsDelTable_rows_selected))}) #note- renderText() = can use regex & scrolls vertically, renderPrint() = no regex & scrolls horizontally
      return()}
  })

  #If selection is "Yes"
  #Make DT proxy object for quick deselection of rows
  proxy <- dataTableProxy("RowsDelTable") #need to assign ouputDT table as proxytable for selectRows() to work
  observeEvent(input$DeselRows, {selectRows(proxy, NULL)}) #this allows the user to deselect all rows when the button DeselRows is pressed
  
  #If selection is "Yes"
  #Update the table by deleting additional rows
  RowDelTable <- eventReactive(req(input$AddRowDelBtnConf), { #Once confirm button is clicked once = delete these rows
    if(!is.null(input$RowsDelTable_rows_selected)){
      tableNewDel <- tableNewDel()[-unlist(input$RowsDelTable_rows_selected),]
      fluidRow(
        output$eval5msg <- renderText(paste(c("Deleted row(s): ", sort(isolate(input$RowsDelTable_rows_selected))))) #need to use c() within paste() b/c input$RowsDelTable_rows_selected is a list which would repeat w/o c()
      )
      return(tableNewDel)
    }else{ #no user row selection = return table w/o additional row deletion
      tableNewDel <- tableNewDel()
      fluidRow(
        output$eval5msg <- renderText(paste("Deleted no rows, previous table retained"))
      )
      return(tableNewDel) 
    }
  })
  
  #If selection is "Yes"
  #Non eventReactive (single event observer) - when delete button clicked -> show modified table + delete message
   observeEvent(req(input$AddRowDelBtnConf),{ #make a seperate observeEvent() from the above eventReactive() so that each click = show/hide tables (if using eventReactive() it doesn't work)
     hide("RowsDelTable") #Hide the old table
     show("eval5msg") #Show the modified new table + rows deleted
     show("AddRowsDelTable")
     hide("AddRowsDelTableSAVENO") #Hide only "NO" table
   })
      ####PROBLEM = DISABLES THE "deleteRowsBtn" FOR DELETING RANGE OF ROWS IF PAGE IS RESET via SelectSheet
      #This part is not really necessary b/c it forces the user to click on the S1/S2/S3 saved link to view select row deleted table
      #Leaving out
        #NOTE - I've since separated the "deleteRowsBtn" events into eventReactive (for calculations) & observeEvent (for messages)
        #This may work now but I'm leaving it out anywyas b/c I think it's better this way
  
  #If selection is "Yes"
  #Render new modified table
  output$AddRowsDelTable <- renderDT(RowDelTable(), options = list("pageLength" = 50))  
  #Render naming + save button
  output$cachetable<- renderUI({ #Make UI appear to show message of saving new table after new table rendered
    conditionalPanel(condition="output.AddRowsDelTable", #Note condtion panel is written in JS which uses input.ID instead of input$ID)
                     fluidRow(                                                           #at this point the tables assigned: input$ChoiceRowDel == "Yes" -> RowDelTable(), while input$ChoiceRowDel == "No" -> tableNewDel()
                       column(7,
                              textInput(
                                inputId="cacheMsg",
                                label="Give a Name to the Save State",
                                value=NULL)),
                       column(3,
                              selectInput(
                                inputId="saveslot",
                                label="Save Slot",
                                choices=c("Slot 1", "Slot 2", "Slot 3"),
                                selected="Slot 1")),
                       column(2, style = "margin-top: 25px;",
                              actionButton("SaveTbl", "Save", class = "btn-success", icon = icon("check-circle-o")))) #or maybe use "lock" icon?
    )
  })

  
  #### NOTE AFTER SPENDING A WHOLE DAY ON THIS PART OF THE CODE -> OBSERVEEVENT NEEDED FOR SINGLE ACTION (IE) UPDATE SAVESTATE NAME PER CLICK OF SAVETBL BUTTON) ALSO NEED TO PLACE REACTIVE TABLE (ROWDELTABLE()) INTO REACTIVEVALUES FOR STATIC VALUES PER SAVE (WORKS IF PRIOR TABLE TABLENEWDEL IS BEING REACTIVELY UPDATED INTO ROWDELTABLE)
  observeEvent(req(input$SaveTbl), {
    hide("RowsDelTable")
    show("AddRowsDelTable")
    shinyjs::disable("AddRowDelBtnConf") #disable delete + deselect rows button when table is saved
    shinyjs::disable("DeselRows")
    
    #Making & Clicking save states
      #IF "YES" CHOICE
    values <- reactiveValues(df=RowDelTable()) #makes a reactive value non-reactive (ie) makes this reactive row deleted table non-reactive) = save state (basically makes plot static & new changes, but if dynamic plot=saves state of plot per change)
    delmsg <- reactiveValues(delmsg=sort(input$RowsDelTable_rows_selected)) #make selected rows from (input$mt) into non-reactive so I can append deleted rows per saved state
    
    output$loadsave0 <- renderUI({
      fluidRow(
        downloadButton("S0download", "Download Unmodified (0)", class = "btn-sm btn btn-warning"),
        actionLink("OriginalTableLink", label="Slot 0: Prior Table (Click to re-modify)")) #show UI to add prior modified table + download button
    })
    
    if(!is.null(input$cacheMsg) && input$saveslot == "Slot 1"){ #If dropdown selection = "Slot 1" + non-empty(null-name) typed then evaluate the below (+including save button press -not in "If" statement b/c main function already requires button press for this to evaluate)
      output$loadsave1 <- renderUI({
        fluidRow(
          downloadButton("S1download", "Download Unmodified (1)", class = "btn-sm btn btn-warning"),
          actionLink("S1", label=paste("Slot 1: ", isolate(input$cacheMsg))))
      }) #show UI to add saved link=S1 + download button
      observeEvent(req(input$SaveTbl), {  #server to make modified table when SaveTbl is clicked + (if statement evaluates for Slot 1 "If saveslot=slot1)
        tableNewDelSave1 <<- values$df #Assign the staticly saved df as a new variable (required for uniqueID for download) ##NOTE- use "<<-" to assign as environmental variable for downloading b/c since in "if" function a normal "<-" won't save to env
        output$AddRowsDelTableSAVE1 <- renderDT(server=F, {(datatable(tableNewDelSave1, filter = "top", editable="cell", 
                                                                      extensions = c('RowReorder', 'ColReorder', "Buttons"),
                                                                      options = list("pageLength" = 50, order = list(list(0, 'asc')), rowReorder = T, colReorder=T,
                                                                                     dom = "Bfrtip", buttons = list(list(extend = 'collection', buttons ='print', text = 'Print (broken)'),
                                                                                                                    list(extend = 'collection', buttons = 'copy', text = 'Copy Whole Table'), 
                                                                                                                    list(extend = 'collection', buttons = c('csv', 'excel', 'pdf'), text = 'Download Modified Table'))
                                                                      ))
        )})
        #(dom = "Bfrtip", buttons = list("csv")) for buttons extension | list(list(0, 'asc')) for roworder to not maintain row number when moved - rownames=F to prevent rownames for when saving table (may have unexpected effects))
        # Must have server=F for rowReorder to work
        output$eval5msg1 <- renderText(paste(c("Deleted Row(s):", delmsg$delmsg)))
        return(tableNewDelSave1)
      })
    }else if(input$saveslot=="Slot 2"  && !is.null(input$cacheMsg)){
      output$loadsave2 <- renderUI({
        fluidRow(
          downloadButton("S2download", "Download Unmodified (2)", class = "btn-sm btn btn-warning"),
          actionLink("S2", label=paste("Slot 2: ", isolate(input$cacheMsg))))
      })
      observeEvent(req(input$SaveTbl), { #server to make modified table
        tableNewDelSave2 <<- values$df
        output$AddRowsDelTableSAVE2 <- renderDT(server=F, {(datatable(tableNewDelSave2, filter = "top", editable="cell", 
                                                                      extensions = c('RowReorder', 'ColReorder', "Buttons"),
                                                                      options = list("pageLength" = 50, order = list(list(0, 'asc')), rowReorder = T, colReorder=T,
                                                                                     dom = "Bfrtip", buttons = list(list(extend = 'collection', buttons ='print', text = 'Print (broken)'),
                                                                                                                    list(extend = 'collection', buttons = 'copy', text = 'Copy Whole Table'), 
                                                                                                                    list(extend = 'collection', buttons = c('csv', 'excel', 'pdf'), text = 'Download Modified Table'))
                                                                      ))
        )})
        output$eval5msg2 <- renderText(paste(c("Deleted Row(s):", delmsg$delmsg)))
        return(tableNewDelSave2)
      })
    }else if(input$saveslot=="Slot 3"  && !is.null(input$cacheMsg)){
      output$loadsave3 <- renderUI({
        fluidRow(
          downloadButton("S3download", "Download Unmodified (3)", class = "btn-sm btn btn-warning"),
          actionLink("S3", label=paste("Slot 3: ", isolate(input$cacheMsg))))
      })
      observeEvent(req(input$SaveTbl), { #server to make modified table
        tableNewDelSave3 <<- values$df
        output$AddRowsDelTableSAVE3 <- renderDT(server=F, {(datatable(tableNewDelSave3, filter = "top", editable="cell", 
                                                                      extensions = c('RowReorder', 'ColReorder', "Buttons"),
                                                                      options = list("pageLength" = 50, order = list(list(0, 'asc')), rowReorder = T, colReorder=T,
                                                                                     dom = "Bfrtip", buttons = list(list(extend = 'collection', buttons ='print', text = 'Print (broken)'),
                                                                                                                    list(extend = 'collection', buttons = 'copy', text = 'Copy Whole Table'), 
                                                                                                                    list(extend = 'collection', buttons = c('csv', 'excel', 'pdf'), text = 'Download Modified Table'))
                                                                      ))
        )})
        output$eval5msg3 <- renderText(paste(c("Deleted Row(s):", delmsg$delmsg)))
        return(tableNewDelSave3)
      })
    }else{
      #Don't need this b/c even if the user doesn't type anything it will evaluate as a character (not sure why, don't want to find out b/c trivial)
    }
  })
  
  
  #S1/2/3 graph view buttons
  observeEvent(req(input$OriginalTableLink), { #click on link = restore old table & allows re-selecton of rows to delete
    #updateTextInput(session, "cacheMsg", value=NULL) #reset input textbox  -> this doesn't work
    show("RowsDelTable")
    hide("AddRowsDelTable")
    hide("AddRowsDelTableSAVE1")
    hide("AddRowsDelTableSAVE2")
    hide("AddRowsDelTableSAVE3")
    hide("eval5msg")
    hide("eval5msg1")
    hide("eval5msg2")
    hide("eval5msg3")
    shinyjs::enable("AddRowDelBtnConf") #re-enable delete + deselect + save rows button when slot0 original old unmodified table is selected
    shinyjs::enable("DeselRows")
    shinyjs::enable("SaveTbl")
    hide("AddRowsDelTableSAVENO") #Hide only "NO" table
    hide("RenamedTable")
  })  
  
  observeEvent(req(input$S1), { #server to return saved table when S1 clicked
    hide("RowsDelTable") #Hide the old table
    hide("AddRowsDelTable") #Hide the modified new table
    show("AddRowsDelTableSAVE1") #show the modified old table assigned to another input (this maybe redundant, IDK don't want to test at this point)
    hide("AddRowsDelTableSAVE2") #hide all the other save state tables
    hide("AddRowsDelTableSAVE3")
    hide("eval5msg")
    show("eval5msg1")
    hide("eval5msg2")
    hide("eval5msg3")
    shinyjs::enable("S1download")
    shinyjs::disable("AddRowDelBtnConf") #disable the delete + deselect rows buttons to prevent re-evaluation on saved state table
    shinyjs::disable("DeselRows")
    shinyjs::disable("SaveTbl") #disable save table button to prevent confusion
    hide("AddRowsDelTableSAVENO") #Hide only "NO" table
    hide("RenamedTable")
  })

  observeEvent(req(input$S2), { #server to return saved table
    hide("RowsDelTable")
    hide("AddRowsDelTable")
    hide("AddRowsDelTableSAVE1")
    show("AddRowsDelTableSAVE2")
    hide("AddRowsDelTableSAVE3")
    hide("eval5msg")
    hide("eval5msg1")
    show("eval5msg2")
    hide("eval5msg3")
    shinyjs::enable("S2download")
    shinyjs::disable("AddRowDelBtnConf")
    shinyjs::disable("DeselRows")
    shinyjs::disable("SaveTbl")
    hide("AddRowsDelTableSAVENO") #Hide only "NO" table
    hide("RenamedTable")
  })
  
  observeEvent(req(input$S3), { #server to return saved table
    hide("RowsDelTable")
    hide("AddRowsDelTable")
    hide("AddRowsDelTableSAVE1")
    hide("AddRowsDelTableSAVE2")
    show("AddRowsDelTableSAVE3")
    hide("eval5msg")
    hide("eval5msg1")
    hide("eval5msg2")
    show("eval5msg3")
    shinyjs::enable("S3download")
    shinyjs::disable("AddRowDelBtnConf")
    shinyjs::disable("DeselRows")
    shinyjs::disable("SaveTbl")
    hide("AddRowsDelTableSAVENO") #Hide only "NO" table
    hide("RenamedTable")
  })
  
  
  #Download button server side save 
  output$S0download <- downloadHandler(
    filename = function() {
      paste0(format(Sys.Date(), format=("%y%m%d")), "_Save0", ".xlsx") #paste0 default sep="" vs paste=" "
    },
    content = function(file) {  #note -- best practice is to save as .tsv b/c european people use commas in their numbers but w/e
      write.xlsx(tableNewDel(), file, showNA=F)
    }
  )
  
  output$S1download <- downloadHandler(
    filename = function() {
      paste0(format(Sys.Date(), format=("%y%m%d")), "_Save1", ".xlsx")
    },
    content = function(file) {  
      write.xlsx(tableNewDelSave1, file, showNA=F)
    }
  )
  
  output$S2download <- downloadHandler(
    filename = function() {
      paste0(format(Sys.Date(), format=("%y%m%d")), "_Save2", ".xlsx")
    },
    content = function(file) {  
      write.xlsx(tableNewDelSave2, file, showNA=F)
    }
  )
  
  output$S3download <- downloadHandler(
    filename = function() {
      paste0(format(Sys.Date(), format=("%y%m%d")), "_Save3", ".xlsx")
    },
    content = function(file) {  
      write.xlsx(tableNewDelSave3, file, showNA=F)
    }
  )
  
  ####################### CONDITION NO BELOW###########################
  #if "No"
  #choice remaining is no -> skip s8 to save (TEST env-var) via: assign current table: tableNewDel() to RowDelTableNO() which matches the variable in the "Yes" route -> output$cachetable -> TEST
  #need to separate from above "YES" observeEvent() b/c requires eventReactive to assign reactive table tableNewDel() into another reactive variable (RowDelTableNO() which is similar to RowDelTable() generated in "Yes" path)
  RowDelTableNO <- eventReactive(req(input$AddRowDelBtn), { #using reactive b/c want to continously delete seleted rows w/o each button click
    if(input$ChoiceRowDel == "No"){
      tableNewDel <- tableNewDel()
      return(tableNewDel)
    }
  })
  #Render "NO" table
    #Basically skip all step including save-state & save button to allow direct modification of the table
  observeEvent(req(input$AddRowDelBtn),{ #need a seperate "single event once clicked" option that if "NO" choice is selected -> hide old table & show new
    if(input$ChoiceRowDel == "No"){
      hide("RowsDelTable") #Hide the old table
      hide("RenamedTable") #hide all other tables incase of re-select sheet
      hide("AddRowsDelTable") 
      hide("AddRowsDelTableSAVE1")
      hide("AddRowsDelTableSAVE2")
      hide("AddRowsDelTableSAVE3")
      show("AddRowsDelTableSAVENO") #Show only "NO" table
      valuesNO <- reactiveValues(df=RowDelTableNO()) #makes a reactive value non-reactive (ie) makes this reactive row deleted table non-reactive) = save state (basically makes plot static & new changes, but if dynamic plot=saves state of plot per change)
      tableNewDelSaveNO <<- valuesNO$df
      output$AddRowsDelTableSAVENO <- renderDT(server=F, {(datatable(tableNewDelSaveNO, filter = "top", editable="cell", 
                                                                     extensions = c('RowReorder', 'ColReorder', "Buttons"),
                                                                     options = list("pageLength" = 50, order = list(list(0, 'asc')), rowReorder = T, colReorder=T,
                                                                                    dom = "Bfrtip", buttons = list(list(extend = 'collection', buttons ='print', text = 'Print (broken)'),
                                                                                                                   list(extend = 'collection', buttons = 'copy', text = 'Copy Whole Table'), 
                                                                                                                   list(extend = 'collection', buttons = c('csv', 'excel', 'pdf'), text = 'Download Modified Table'))
                                                                     ))
      )})
    }
  })
  
  
###############INSTRUCTIONS SECTION##############
  
  output$InstructionsText <- renderUI(HTML(paste("<font size='3'>",
                                                 "<font size=5>&#10122;</font> Upload excel file to modify <b><mark style='background-color:lightblue'>(Only .xlsx or .xls format is supported [5MB limit])</mark></b><br>", #note to self options(shiny.maxRequestSize=10*1024^2) = 10MB max
                                                 "<br>",
                                                 "<font size=5>&#10123;</font> Select page to modify <br>",
                                                 "&emsp;   &#10154; You can re-select a page to reset <br>",
                                                 "<br>",
                                                 "<font size=5>&#10124;</font> Type in row# you wish to set a column names & click button<br>",
                                                 "&emsp;   &#10154; Entering a value =0 means no new column names will be assigned<br>",
                                                 "<br>",
                                                 "<font size=5>&#10125;</font> Type in range of rows to remove & click button<br>",
                                                 "&emsp;   &#10154; Setting values as '0 to 0' means no rows will be deleted<br>",
                                                 "<br>",
                                                 "<font size=5>&#10126;</font> Choose choice of deleting additional rows or not & click button<br>",
                                                 "<font size=5>&#10127;</font> If 'Yes' is selected, then select additional row(s) to delete by manually clicking on selected row(s)<br>",
                                                 "&emsp;   &#10154; You can de-select all rows selected by the 'De-select All Rows' button<br>",
                                                 "&emsp;   &#10154; Confirm row(s) deletion by pressing the 'Delete' button<br>",
                                                 "&emsp;   &#10154; If no row(s) are selected, the current table will be returned<br>",
                                                 "&emsp;   <b>&#10163; If 'No' is selected, you can automatically edit the table but it will not be saved to a state (skip below steps, except 10)</b><br>",
                                                 "&emsp;&emsp;   <b>&#10163; Clicking a saved state will automatically exit the 'No' selection table</b><br>",
                                                 "<br>",
                                                 "<font size=5>&#10128;</font> Type a name & select a save-state slot & press save to cache the current table for later modifications & download <br>",
                                                 "&emsp;   &#10154; Two 'Unmodified table' download buttons & associated save states will appear<br>",
                                                 "&emsp;&emsp;   &#10154; Pressing on 'Slot 0' allows you to re-select rows to be deleted from the previous table & cache the output to a saved-state<br>",
                                                 "<br>",
                                                 "<font size=5>&#10129;</font> Pressing on 'Slot #' of saved-state allows you to downlaod that graph & conduct additional modifications <br>",
                                                 "<br>",
                                                 "<font size=5>&#10130;</font> Modify the graph & save by pressing the above  <br>",
                                                 "&emsp;   &#10154; Double click cell to adjust cell value (press ctrl+enter to confirm change)<br>",
                                                 "&emsp;   &#10154; You can select a row or column to move<br>",
                                                 "&emsp;   &#10154;; You can filter certain columns<br>",
                                                 "&emsp;   &#10154; Press 'Download Modified Table' button on top of the graph to save modified table<br>",
                                                 "<br>",
                                                 "<font size=5>&#10131;</font> Profit?!?!? <br>",
                                                 "</font>"))) #test text output  
  
  output$HTMLimg <- renderUI({
    HTML(glue::glue("<center><img src='https://toppng.com/uploads/preview/kool-aid-man-3d-light-fx-hulk-right-fist-11563079227z59tdmmxzj.png' width='800' height='800' style='border:10px outset silver;'></center>
                    <br>
                    <center><b>Uhhh.... Welcome?</b></center>"))
  })
  
##############PLOT SECTION##########################  
  
  #Make default table to aid user-inputs downstream + start a framework required for platetools
  DefaultTable <- data.frame(ID=1:96, 
                             Wells=paste(rep(LETTERS[1:8], each=12), 1:12, sep=""), 
                             Concentration=as.numeric(rep(0, times=96)), #0 = default values
                             Volume=as.numeric(rep(0, times=96)),
                             Comments=as.character(rep("", time=96)))
  
  
  ExampleTable <- data.frame(Wells=paste(rep(LETTERS[1:8], each=12), 1:12, sep=""),  #For example table format tab
                             Concentration=round(rnorm(n=96, mean=20, sd=5), 1),
                             Volume=round(rnorm(n=96, mean=50, sd=15), 1),
                             Comments=as.character(rep("Comment Here", time=96))) #Row format DF example
  
  
  ###########
  #Make 96-well plate to plot
  SkipTable <- data.frame(ID=1:96, 
                          Wells=paste(rep(LETTERS[1:8], each=12), 1:12, sep=""),
                          SampleName=rep("Sample", times=96),
                          Concentration_mM=round(rnorm(n=96, mean=20, sd=5), 1), #0 = default values
                          Volume_uL=round(rnorm(n=96, mean=50, sd=15), 1),
                          Comments=as.character(rep("Comment Here", time=96)))
  
  #Get positions of rows/columns for 96-well plate
    #https://rstudio-pubs-static.s3.amazonaws.com/427185_abcc25a951c9436680dc6a8fcc471ca9.html
    #https://stackoverflow.com/questions/6919025/how-to-assign-colors-to-categorical-variables-in-ggplot2-that-have-stable-mappin
  SkipTable <- mutate(SkipTable,
                      Row=as.numeric(match(toupper(substr(Wells, 1, 1)), LETTERS)),
                      Column=as.numeric(substr(Wells, 2, 5)))
  
  
  plate= ggplot(data=SkipTable, aes(x=Column, y=Row)) + #this part sets up plate layout
    geom_point(data=expand.grid(seq(1, 12), seq(1, 8)), aes(x=Var1, y=Var2),
               color="grey90", shape=21) +
    coord_fixed(ratio=(13/12)/(9/8), xlim=c(0.5, 12.5), ylim=c(0.5, 8.5)) + 
    scale_y_reverse(breaks=seq(1, 8), labels=LETTERS[1:8]) + #give y-labels of A-H
    scale_x_continuous(breaks=seq(1, 12), position = "top") + #change X-labels to 1:12 & put axis on top
    labs(title="96 - well Plate Template")
  
  names(plate$data)
  
  plate1 <- plate + geom_point(aes(alpha=Concentration_mM, colour=Volume_uL), size = 8) #add col variables here
 
  #isTruthy()#isTruthy() checks all possibilities (i.e. NULL, NA, "", numeric(0) etc
  
  #Disable all selections until conditions met (+some buttons)
  disable("ConcSelect")
  disable("VolSelect") 
  disable("CommentSelect")
  disable("AddColsBtn")
  disable("AddRowsBtn")
  
  ######Example Table Tab############
  output$RowExTXT <- renderText("Row Formatting")
  output$EXtab1 <- renderTable(t(ExampleTable), options= list("pageLength" = 4), include.rownames=T)
  
  output$ColExTXT <- renderUI(HTML("<b><font size=10>OR</font></b>
                                    <br> 
                                    Column Formatting")) 
  output$EXtab2 <- renderTable(ExampleTable, options= list("pageLength" = 96))
  
  ######Uploaded Table Tab############
  #Plot uploaded table in 'Uploaded Table' tab
  output$ULtable <- renderDT(server=F, {(datatable(PlotUploadedTable$df, editable="cell", 
                                                   selection = list(mode ='multiple', target = 'cell'), #note this gives output of input$tableId_cells_selected
                                                   options = list("pageLength" = 100, order = list(list(0, 'asc')))
  ))})
  #Add Rows/Column
  proxy1 <- dataTableProxy("ULtable") #make proxy object of uploaded output table to enable DT package functions on table edit
  #Add rows
  #https://yihui.shinyapps.io/DT-proxy/
  #observeEvent(eventExpr = input$AddRowsBtn, {
  #  addRow(proxy1, PlotUploadedTable$df[(length(rownames(PlotUploadedTable$df))+1), ,drop = FALSE]) #use [length(colnames(PlotUploadedTable()+ 1 to calculate number of existing columns(+1) to specify next empty column to add -> add range(:input$AddNR), all columns, drop=F]
  #})
  #Note-addRows is a DT function but there is no addCols function
  #Note-removed this b/c it doesn't work with the below addcols function I made -> due to DT function (idk what specifically, probably b/c proxy table needed)
  observeEvent(req(input$AddColsBtn), { 
    PlotUploadedTable$df <<- rbind(PlotUploadedTable$df, "")
  })
  
  #Add cols
  #https://stackoverflow.com/questions/48471042/button-to-add-entry-column-to-r-shiny-datatable
  observeEvent(req(input$AddColsBtn), { 
    PlotUploadedTable$df <<- cbind(PlotUploadedTable$df, "")
  })
  
  #for some reason this works but sometimes one button conflicts with the other until the other is pressed
  #figure it out some other time
  
  
  #This allows DT table edited cells to retain values (without it & just using the editable function = does not retain)
  #see here: https://stackoverflow.com/questions/50470097/r-shiny-dt-edit-values-in-table-with-reactive
  observeEvent(input$ULtable_cell_edit, {
    info = input$ULtable_cell_edit
    str(info)
    i = info$row
    j = info$col
    v = info$value
    # problem starts here
    PlotUploadedTable$df[i, j] <- isolate(DT::coerceValue(v, PlotUploadedTable$df[i, j]))
  })
  
  
  
  ######Interactive Table Tab############
  ##Upload button
  #Extract all sheet names in excel file 
  UploadPlot <- eventReactive(req(input$UploadIDplot), {    #get $datapath for reading in excel sheet
    TabNameListplot <- readxl::excel_sheets(input$UploadIDplot$datapath) #Get sheet names individually
    list(TabNameListplot=TabNameListplot) # NOTE TO RECALL VARIABLES IN FUNCTION(Uploadplot) -> MUST PLACE VARIABLES AS A LIST
  })
  
  #Upload the table 
  #Make empty reactiveValues to store values of uploaded/selected sheet -> MORE WORKABLE VS var <- eventReactive()
  PlotUploadedTable <- reactiveValues(df=NULL)
  
  #Make reactive event when selection is made = return the values of the sheet selected
  UpSheets <- eventReactive(input$SelectSheetplot, {
    if(!is.null(input$UploadIDplot) && #If uploadID (upload file is not NULL) &
       (input$SelectSheetplot %in% UploadPlot()$TabNameListplot)) { #If Selected sheet from dropdown == in list of sheet names
      return(read_excel(input$UploadIDplot$datapath, sheet = input$SelectSheetplot, col_names=F))
    }
  })
  
  #Put the values into the blank reactiveValues df (this makes it easier to work with)
  observeEvent(input$SelectSheetplot, {
    PlotUploadedTable$df <- UpSheets()
    return(PlotUploadedTable$df) #If above is true, then read excel based upon selected sheet
  })
  
  
  #Update choices in SelectInput to reflect sheets uploaded
  observe({updateSelectInput(session, "SelectSheetplot", choices=UploadPlot()$TabNameListplot)}) #Only works w/ observe b/c updates per single change == Re-fresh/Reset functionality
  
  #Upload Msg
  #https://gist.github.com/ijlyttle/6230575
  #Actively(reactively) check if a file is uploaded -> assign it to a non-existing output(import_ready)
  output$import_ready <- reactive({return(!is.null(input$UploadIDplot))})
  #Non-existing ouput object (import_ready) is not hidden/suspended -> making it exist
  outputOptions(output, "import_ready", suspendWhenHidden = FALSE)
  #Make conditional where if import_ready exists/is present, then make textUI and render at the same time
  output$LookAtTabMsg <- renderText(paste("Click on 'Uploaded Table' Tab to View Uploaded Table \n", #Evaluate UI & output instruction message
                                          "Manually Select Cells Containing: \n",
                                          "Concentrations/Volumes/Comments \n",
                                          "(Note: Shift+Click for Range Selection)"))
  
  ##Uploaded table
  #Enable concentration selection + Add rows/cols buttons
  observeEvent(req(input$UploadIDplot), {
    enable("ConcSelect")
    enable("AddRowsBtn")
    enable("AddColsBtn")
  })
  
  #Display Selection Table
  #Make reactive selection table to update values per selection
  # reactivetbl <- reactiveValues(df=DefaultTable)
  reactivetbl <- reactiveValues(df=SkipTable) ####################Note using a cheat table to show plotting (above is the correct env for this)
  
  #disallow certain columns from edit: https://github.com/rstudio/DT/pull/657remotes::install_github('rstudio/DT')
  #https://stackoverflow.com/questions/55690492/r-shiny-editing-dt-with-locked-columns
  output$SelectionTable <- renderDT(server=F, {(datatable(reactivetbl$df, editable = list(target = "column", disable = list(columns = c(1,2))), #note removing "f" from dom="" makes the search bar disasspear ("t" "p" = page & #rows)
                                                          extensions = c("Buttons"),
                                                          options = list("pageLength" = 96, order = list(list(0, 'asc')),
                                                                         dom = "Br", buttons = list(list(extend = 'collection', buttons ='print', text = 'Print (broken)'),
                                                                                                    list(extend = 'collection', buttons = 'copy', text = 'Copy Whole Table'), 
                                                                                                    list(extend = 'collection', buttons = c('csv', 'excel', 'pdf'), text = 'Download Modified Table')),
                                                                         columnDefs = list(list(visible=FALSE, targets=c(1,7,8))) #where targets=columns to hide
                                                          )))
  })
  
  
  #Conc selection
  #reactive(reactivetbl$df$Concentration <- as.data.frame(PlotUploadedTable$df)[input$ULtable_cells_selected]) #Note: this took awhile but I figured out how to extract single cell values from a selected cell T_T (important = use reactivevalues to store df)
  #note: this means assign to reactivevalue (reactivetbl$df)$column
  #Doesn't work -> want to select 96 cells/rows/columns (need to decide via adding nr input or something to ask which rows/cols for 96cells)
  #Once selected, should replace the values in default table
  #DefaultTable$Concentration <- as.data.frame(PlotUploadedTable$df)[input$ULtable_cells_selected])
  #or something
  #then re-eanble volumes input bar & repeat
  #then repeat for comments
  #May be too ambitious -> stopped 20/06/29
  
  #Vol selection
  #Comment selection
  
  
  #Plot Interactive
  observeEvent(req(input$GenerateBtn), { #click generate button to render plot
    output$InteractivePlot <- renderPlot(plate1, res=96)
    output$TTT <- renderTable(nearPoints(SkipTable, input$click, xvar="Column", yvar="Row")) #nearPoints() will link table to plot w/ input$click (InteractivePlot))
  })
  
  #This gives coordinates of click points       
  # output$InteractivePlotMsg <- renderPrint({
  #      req(input$click)
  #      x <- round(input$click$x, 2)
  #      y <- round(input$click$y, 2)
  #      cat("[", x, ", ", y, "]", sep = "")
  #    })
  #  })
  
  output$test <- renderText(paste(as.data.frame(PlotUploadedTable$df)[input$ULtable_cells_selected])) #Debugging w/ comment outputs
  
  
}

shinyApp(ui, server)

#rstudioapi::viewer("http://127.0.0.1:5291")


####Table editor
#Buttons list
# selectHeaderBtn make header
# deleteRowsBtn delete rows
# AddRowDelBtn confirm
# AddRowDelBtnConf delete these rows
# DeselRows deselect rows
# SaveTbl save

#Tables list
# RenamedTable
# RowsDelTable
# AddRowsDelTable
# AddRowsDelTableSAVE1
# AddRowsDelTableSAVE2
# AddRowsDelTableSAVE3
# AddRowsDelTableSAVENO

#hide/show debugging
#generate wells photo

#https://stackoverflow.com/questions/56535488/how-to-download-editable-data-table-in-shiny
#Limitation of using column/row reorder == filter function of renderDT() doesn't work properly (see here: https://github.com/rstudio/DT/issues/534)
#observeEvent explaination: https://stackoverflow.com/questions/52880829/outputtable-based-on-a-data-frame-from-an-observe-event
#https://stackoverflow.com/questions/43217170/creating-a-reactive-dataframe-with-shiny-apps