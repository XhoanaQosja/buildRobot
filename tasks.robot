*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           Dialogs
Library           RPA.Robocorp.Vault


*** Keywords ***
Open the robot order website
    Open Browser   https://robotsparebinindustries.com/#/robot-order  chrome

*** Keywords ***
Get orders
     ${url}=       Get secret   data 
     Download    ${url}[url]    overwrite=True 
     ${total}=    Read table from CSV           orders.csv
     [Return]     ${total}

*** Keywords ***
Close the annoying modal
    Click Element    xpath=/html/body/div/div/div[2]/div/div/div/div/div/button[2]

*** Keywords *** 
Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    ${string}  set variable      id-body-${row}[Body]
    Click element  xpath= //label[@for="${string}"]
    Input Text     xpath= //input[@placeholder="Enter the part number for the legs"]     ${row}[Legs]
    Input Text     xpath= //input[@placeholder="Shipping address"]    ${row}[Address]
    Click Button   order

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]  ${nr}
    Wait Until Keyword Succeeds    10s    0.5    wait for receipt
    ${receipt_html}=    Get Element Attribute    id:receipt   outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipts${/}receipt_${nr}.pdf
    [return]    ${CURDIR}${/}output${/}receipts${/}receipt_${nr}.pdf



***keywords***
Wait for receipt
   ${state}=   run keyword and return status  element should be visible    id:receipt
   run keyword unless  ${state}  Click button   order
   Element should be visible   id:receipt

***keywords***
Go to order another robot
    Click element    id:order-another

***keywords***
Create a ZIP file of the receipts
    Archive Folder With Zip  ${CURDIR}${/}output${/}receipts  mydocs.zip

***keywords***
Take a screenshot of the robot
    [Arguments]  ${nr}
    #${image_html}=    Get Element Attribute    id:robot-preview   outerHTML
    ${image_html}=   Capture element screenshot       xpath=/html/body/div/div/div[1]/div/div[2]    ${CURDIR}${/}output${/}screenshots${/}scr_${nr}.png
    [return]    ${CURDIR}${/}output${/}screenshots${/}scr_${nr}.png

***keywords***
Embed the robot screenshot to the receipt PDF file
   [Arguments]  ${screenshot}    ${pdf}
   Open PDF   ${pdf}
   ${files}    Create list 
   ...         ${screenshot}
   Add Files To Pdf    ${files}    ${pdf}   append=True
   Close PDF    ${pdf}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
       Close the annoying modal
       Fill the form    ${row}
       ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
       ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
       Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
       Go to order another robot
    END
    Create a ZIP file of the receipts

