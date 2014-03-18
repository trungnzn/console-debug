<%@ Page Language="C#" MasterPageFile="~/Main.Master" AutoEventWireup="true" ValidateRequest="false" CodeFile="EventDetails.aspx.cs"
    Inherits="EventDetails" Title="Event Details" %>
<asp:Content ID="Content1" ContentPlaceHolderID="PageHeaderContentPlaceHolder" runat="Server">
    Event Details</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="PageContentPlaceHolder" runat="Server">
        <script type="text/javascript">
            $(document).ready(function () {
                getEventBudgetSummary($get('<%= EventID.ClientID  %>').value);
                $(".Title").text($get('<%= EventName.ClientID  %>').value);

                $('#<%=UploadImageAction.ClientID %>').hide();

                if (($get('<%= JobCodeVal.ClientID  %>').value) == 'Z_EVENTTEMPLATE') {
                    $("#registrationsTab").css("display", "none");
                    $("#attendeesTab").css("display", "none");
                    $("#invoiceTab").css("display", "none");
                    $("#budgetTab").css("display", "none");
                    $("#adonNotTemplate").css("display", "none");
                } else {
                    $("#adonTemplate").css("display", "none");
                }

                // BEGIN: CALCULATE GST
                function calculateTotalCharge(currentItem) {
                    var parent = currentItem.parent().parent().parent().parent();
                    var groupQtyCharged = parent.find(".Item[class*=GroupQtyCharged]").first().children(".Value").first().children(":input").first().val();
                    var seatsPerGroup = parent.find(".Item[class*=EventSeatsPerGroup]").first().children(".Value").first().children(":input").first().val();

                    var quantity = ((parseFloat(groupQtyCharged) > 0) ? parseFloat(groupQtyCharged) : 0) * seatsPerGroup;
                    parent.find(".Item[class*=Quantity]").first().children(".Value").first().children(":input").first().val(quantity);

                    // get price
                    var price = parent.find(".Item[class*=Price]").last().children(".Value").first().children(":input").first().val();
                    var numberPrice = Number(price.replace(/[^0-9\.]+/g, ""));

                    var result = ((parseFloat(groupQtyCharged) > 0) ? parseFloat(groupQtyCharged) : 0) * ((parseFloat(numberPrice) > 0) ? parseFloat(numberPrice) : 0);
                    if (result == null) result = 0;
                    result = "$" + result.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, "$1,");

                    // display result
                    parent.find(".Item[class*=TotalCharge]").first().children(".Value").first().children(":input").first().val(result);
                    parent.find(".Item[class*=TotalCharge]").first().children(".Value").contents().filter(function () { return this.nodeType == 3; }).replaceWith(result);

                    calculateTotalGST();
                }
                function calculateTotalGST() {
                    var totalInc = 0;
                    var totalExc = 0;
                    var taxRateNo = 0;

                    $(".Item[class*=TotalCharge]").each(function () {
                        var val = $(this).first().children(".Value").first().children(":input").first().val();
                        totalExc += Number(val.replace(/[^0-9\.]+/g, ""));
                    });

                    taxRateNo = $("#ctl00_PageContentPlaceHolder_DataViewExtender2_Item810").val();
                    totalInc = totalExc + (totalExc * (taxRateNo / 100));

                    var totalIncStr = "$" + totalInc.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, "$1,");
                    var totalExcStr = "$" + totalExc.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, "$1,");

                    //Dispaly Total Including GST
                    $("#ctl00_PageContentPlaceHolder_DataViewExtender2_Item808").val(totalIncStr);
                    $("#ctl00_PageContentPlaceHolder_DataViewExtender2_ItemContainer808").first().children(".Value").contents().filter(function () { return this.nodeType == 3; }).replaceWith(totalIncStr);
                    //Dispaly Total Excluding  GST
                    $("#ctl00_PageContentPlaceHolder_DataViewExtender2_Item809").val(totalExcStr);
                    $("#ctl00_PageContentPlaceHolder_DataViewExtender2_ItemContainer809").first().children(".Value").contents().filter(function () { return this.nodeType == 3; }).replaceWith(totalExcStr);
                }

                //Call calculate()
                $("#registrationsTab").delegate(".Item[class*=GroupQtyCharged]", "change", function (event) {
                    event.preventDefault();
                    var idItem = $(this).children(".Value").first().children(":input").first().attr("id");
                    calculateTotalCharge($("#" + idItem));
                    identifyProductHasQty($("#" + idItem), 1);
                });

                $("#registrationsTab").delegate(".Item[class*=Price]", "change", function (event) {
                    event.preventDefault();
                    var idItem = $(this).children(".Value").first().children(":input").first().attr("id");
                    calculateTotalCharge($("#" + idItem));
                });
                // END: CALCULATE GST & SET DEFAULT

                // BEGIN: SET DEFAULT PRODUCT FOR ATTENDEE
                $("#registrationsTab").delegate("[title*='Select Attendee']", "click", function (event) {
                    var lookupSelectId = $(this).parent().parent().parent().parent().parent();
                    dynamicDefaultProductForAttendee(lookupSelectId);
                });
                
                $("#registrationsTab").delegate("[title*='New Attendee']", "click", function (event) {
                    var lookupNewId = $(this).parent();
                    dynamicDefaultProductForAttendee(lookupNewId);
                });

                $("#registrationsTab").delegate(".Item[class*=GroupQtyFree]", "change", function (event) {
                    event.preventDefault();
                    var idItem = $(this).children(".Value").first().children(":input").first().attr("id");
                    identifyProductHasQty($("#" + idItem), 2);
                });

                function identifyProductHasQty(productId, type) {
                    var parent = productId.parent().parent().parent().parent();
                    var rowCount = 0;
                    var tmpRow = 0;

                    if (type == 2) {
                        var groupQtyFree = parent.find(".Item[class*=GroupQtyFree]").first().children(".Value").first().children(":input").first().val();
                        var seatsPerGroup = parent.find(".Item[class*=EventSeatsPerGroup]").first().children(".Value").first().children(":input").first().val();

                        var quantityFree = ((parseFloat(groupQtyFree) > 0) ? parseFloat(groupQtyFree) : 0) * seatsPerGroup;
                        parent.find(".Item[class*=ComplimentaryQuantity]").first().children(".Value").first().children(":input").first().val(quantityFree);
                    }

                    $(".ProductList").each(function () {
                        var tmpQtyCharged = $(this).find(".Item[class*=Quantity]").first().children(".Value").first().children(":input").first().val();
                        var tmpQtyFree = $(this).find(".Item[class*=ComplimentaryQuantity]").first().children(".Value").first().children(":input").first().val();

                        var tmpQty = ((parseFloat(tmpQtyCharged) > 0) ? parseFloat(tmpQtyCharged) : 0) + ((parseFloat(tmpQtyFree) > 0) ? parseFloat(tmpQtyFree) : 0);
                        if (tmpQty > 0) {
                            rowCount = parseInt(rowCount) + 1;

                            var tmpProductClass = $("#" + $(this).find(".Item[class*=Quantity]").first().attr("id")).attr('class');
                            tmpRow = tmpProductClass.substr(tmpProductClass.length - 1);
                        }
                    });

                    var quantityCharged = parent.find(".Item[class*=Quantity]").first().children(".Value").first().children(":input").first().val();
                    var quantityFree = parent.find(".Item[class*=ComplimentaryQuantity]").first().children(".Value").first().children(":input").first().val();
                    var qty = ((parseFloat(quantityCharged) > 0) ? parseFloat(quantityCharged) : 0) + ((parseFloat(quantityFree) > 0) ? parseFloat(quantityFree) : 0);
                    if (qty > 0) {
                        var currentProductClass = $("#" + productId.parent().parent().attr('id')).attr('class');
                        tmpRow = currentProductClass.substr(currentProductClass.length - 1);
                    }
                    
                    $("#ctl00_PageContentPlaceHolder_DataViewExtender2_Item812").val(rowCount);
                    $("#ctl00_PageContentPlaceHolder_DataViewExtender2_Item811").val(tmpRow);
                }

                function dynamicDefaultProductForAttendee(currentRowId) {
                    var rowHasQty = $("#ctl00_PageContentPlaceHolder_DataViewExtender2_Item811").val();
                    var rowHasQtyCount = $("#ctl00_PageContentPlaceHolder_DataViewExtender2_Item812").val();

                    if (rowHasQtyCount == 1) {
                        var idItem = currentRowId.parent().parent().parent().parent().parent();

                        var currentAttClass = $('#' + idItem.attr("id")).attr('class');
                        var currentAttPosition = currentAttClass.substr(currentAttClass.length - 1);
                        var currentAttValue = currentRowId.children(":input").first().val();

                        //Remove unnecessary value
                        $("#attendeeTable .Lookup").each(function () {
                            var realAtt = $(this).parent().children(":input").first().val();
                            if (realAtt == null || realAtt == "") {
                                var removeId = $(this).parent().parent().parent().parent().parent().parent();
                                var removeClass = $('#' + removeId.attr("id")).attr('class');
                                var removePosition = removeClass.substr(removeClass.length - 1);

                                var checkboxVal = $('#' + removeId.attr("id")).parent().parent().find(".Item[class*=Att" + removePosition + "StockCode" + rowHasQty + "]").first().children(":input").first().val();
                                if (checkboxVal == 1)
                                    $('#' + removeId.attr("id")).parent().parent().find(".Item[class*=Att" + removePosition + "StockCode" + rowHasQty + "]").first().children(":input").first().val(null);
                            }
                        });

                        if (currentAttValue == null || currentAttValue == "")
                            $('#' + idItem.attr("id")).parent().parent().find(".Item[class*=Att" + currentAttPosition + "StockCode" + rowHasQty + "]").first().children(":input").first().val(1);
                    }
                }

                // END: SET DEFAULT PRODUCT FOR ATTENDEE
            });

        function getEventBudgetSummary(jobId) {
            $.ajax({
                url: "../Services/EventBudgetSummaryHandler.ashx",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                data: { 'jobId': jobId },
                responseType: "json",
                success: function (result) {
                    $("#profit").text(result.Profit);
                },
                error: function (xhr, ajaxOptions, thrownError) {
                    alert(xhr.status);
                    alert(thrownError);
                }
            });
            return false;
            return true;
        }
        function updateUploadForm(isUploading) {
            if (isUploading == '1') {
                $("#<%=UploadImageAction.ClientID %>").attr('value', 'Cancel');
                $("#<%=UploadImageActionHidden.ClientID %>").click();
            }
            else {
                $('#ctl00_PageContentPlaceHolder_UploadImageAction').show();
            }
        }

        function updateUploadOnAddOnForm(isUploading) {
            if (isUploading == '1') {
                $("#<%=NewAddOnUploadImageAction.ClientID %>").attr('value', 'Cancel');
                $("#<%=NewAddOnUploadImageActionHidden.ClientID %>").click();
            }
        }

        function showEditAddOnImage(url, title, removeTitle, isUploading) {
            $("#<%=EditAddOnPreviewImageId.ClientID %>").attr('src', '../' + url);
            $("#<%=EditAddOnPreviewImageId.ClientID %>").attr('title', title);
            $("#<%=btnRemoveEditAddOn.ClientID %>").attr('title', removeTitle);

            if (isUploading == '1') {
                $("#<%=EditAddOnUploadImageAction.ClientID %>").click();
                $("#<%=EditAddOnUploadImageAction.ClientID %>").attr('value', 'Edit Image');
            }
        }
        
        function highlightFirstRow() {
            $("#ctl00_PageContentPlaceHolder_DataViewExtender2_Row0").addClass('Selected');
        }

        function updateShowHideAttendees() {
            var dv = $find('ctl00_PageContentPlaceHolder_DataViewExtender2');
            if (dv && (dv._controller == "Registrations") && (dv._viewId == "createForm1")) {  
                hideNullAttendees(registrationsNew);
            }
        }

        function hideNullAttendees(totalOldAttendees) { 
            registrationsNew = totalOldAttendees; 
            $(".Registrations_createForm1 .TabDetailsTable#attendeeTable tr.TabDetailsTR").filter(function () {
                return $(this).attr("row-order") > registrationsNew;
            }).hide();

            $(".Registrations_createForm1 .TabDetailsTable#attendeeTable tr.TabDetailsTR").filter(function () {
                return $(this).attr("row-order") <= registrationsNew;
            }).show();
        }
        var registrationsNew = 5;
        $(function () {
            $("#attendees-add-btn").live("click", function () {
                registrationsNew++;
                if ($("#ctl00_PageContentPlaceHolder_DataViewExtender2_Item106").length != 0) {
                    $("#ctl00_PageContentPlaceHolder_DataViewExtender2_Item106").val(registrationsNew);
                }
                $("tr[row-order='" + registrationsNew + "']").show();
                $("#attedeeContainer").scrollTop($("#attedeeContainer")[0].scrollHeight);
                if (registrationsNew == 50) {
                    $(this).hide();
                }
                return false;
            });

            updateShowHideAttendees();
        });

        </script>
    <asp:HiddenField runat="server" ID="EventID" />
    <asp:HiddenField runat="server" ID="JobCodeVal" />
    <asp:HiddenField runat="server" ID="CountPrice" />
    <asp:HiddenField runat="server" ID="EventName" />
    <div factory:flow="NewRow" xmlns:factory="urn:codeontime:app-factory">
        <div factory:activator="Tab|General">
            <div factory:flow="NewRow" xmlns:factory="urn:codeontime:app-factory"> 
                <div id="view1" runat="server">
                </div>
                <aquarium:DataViewExtender id="DataViewExtender1" runat="server" TargetControlID="view1" Controller="Events" view="editForm1" ShowActionBar="false"/>
                
                <div id="Events_editForm1" style="display:none;">                
                    <table style="width: 100%; padding: 0 10px;" class="TabDetailsTable FieldWrapper Body">
                        <tr class="TabDetailsTR">
                             <td colspan="4"><br /><b>General</b><hr /></td>
                        </tr>
                        <tr class="TabDetailsTR">
                            <td width="15%">Status Reason *</td><td class="CustomItem" width="35%">{JobStatusNo}</td>
                            <td width="15%"></td><td class="CustomItem" width="35%"></td>
                        </tr>
                        <tr class="TabDetailsTR">
                            <td>Name *</td><td class="CustomItem">{JobTitle}</td>
                            <td>Branch</td><td class="CustomItem">{JobBranchNo}</td>
                        </tr>
                        
                        <tr class="TabDetailsTR">
                            <td>Event Code</td><td class="CustomItem" colspan="3"><b>{JobCode}</b></td>
                        </tr>
                        
                        <tr class="TabDetailsTR"><td colspan="4"><hr /></td></tr>
                        <tr class="TabDetailsTR">
                            <td>Event Sales GL Code</td><td class="CustomItem">{StockSalesGLCode}</td>
                            <td>Event Cost GL Code</td><td class="CustomItem">{StockCosGLCode}</td>
                        </tr>
                        <tr><td colspan="4"><br /></td></tr>
                            
                        <tr class="TabDetailsTR">
                            <td>Event Start Date/Time</td><td class="FieldPlaceholder DataOnly">{StockXEventStartDate}</td>
                            <td>Event End Date/Time</td><td class="FieldPlaceholder DataOnly">{StockXEventEndDate}</td>
                        </tr>
                        <tr class="TabDetailsTR">
                             <td colspan="4"><br /><b>Event address details</b><hr /></td>
                        </tr>
                        <tr class="TabDetailsTR">
                            <td>Venue</td><td class="CustomItem">{StockXEventVenue}</td>
                            <td>Room</td><td class="CustomItem">{StockXEventRoom}<span style="display:none">{StockXEventBranch}</span></td>
                        </tr>
                        <tr class="TabDetailsTR">
                            <td>Street</td><td class="CustomItem">{StockEventStreet}</td>
                            <td>Suburb</td><td class="CustomItem">{StockEventStreet2}</td>
                        </tr>
                        <tr class="TabDetailsTR">
                            <td>City</td><td class="CustomItem">{StockEventCity}</td>
                            <td>Country</td><td class="CustomItem">{StockEventCountry}</td>
                        </tr>
                        <tr class="TabDetailsTR">
                            <td>Postcode</td><td class="CustomItem">{StockEventPostcode}</td>
                        </tr>
                        <tr class="TabDetailsTR" style="display:none;">
                            <td>State</td><td class="CustomItem">{StockEventState}</td>
                            <td colspan="2"></td>
                        </tr>
                        <tr class="TabDetailsTR"><td colspan="4"><hr /></td></tr>
                        <tr class="TabDetailsTR">
                            <td>Event in Event List</td><td class="CustomItem">{StockXEventInEventsList}</td>
                            <td></td><td></td>
                        </tr>
                        
                        <tr class="TabDetailsTR">
                             <td colspan="2" class="CustomItem"><span style="visibility: hidden;">{StockImage}</span></td>
                             <td colspan="2" class="CustomItem"><span style="visibility: hidden;">{IsUploading}</span></td>
                        </tr>

                        <tr class="TabDetailsTR">
                            <td colspan="2" valign="top" style="padding-right: 30px;">
                                <b>Event Image</b><hr />
                                <div style="text-align: left; height: 330px;"> 
                                    <asp:UpdatePanel ID="ImageUploadPanel" runat="server">
                                        <ContentTemplate>
                                            <div>
                                                <asp:Image runat="server" ID="PreviewImageId" Width="350px" Height="275px" ImageUrl="" ToolTip="No Image Availble" BorderStyle="Ridge" BorderWidth="5px" BorderColor="White"/>
                                                <asp:ImageButton ID="btnRemove" runat="server" ImageUrl="~/App_Themes/_Shared/image_remove.png" 
                                                    Style="position: relative; top: -4px; left: -40px;" ToolTip="Remove Current Image" Visible="false" OnClick="btnRemove_OnClick"/>
                                            </div>
                                            <div style="left: -35px; padding-bottom: 5px;">
                                                <act:AsyncFileUpload runat="server" ID="ImageUploadId" UploaderStyle="Modern" 
                                                    Visible="false" OnUploadedComplete="ImageUploadId_OnUploadedComplete" Width="359px"
                                                    OnUploadedFileError="ImageUploadId_OnUploadFileError" ThrobberID="imgLoader" CompleteBackColor="White" />
                                            </div>
                                            <div>
                                                <asp:Button ID="UploadImageAction" runat="server" OnClick="UploadImageAction_OnClick" Text="Edit Image" />
                                                <asp:Image ID="imgLoader" runat="server" ImageUrl="~/App_Themes/_Shared/loader.gif"/>
                                            </div>
                                            <div style="visibility: hidden;">
                                                <asp:Button ID="UploadImageActionHidden" runat="server" OnClick="UploadImageActionHidden_OnClick" Text="Hidden Button"/>
                                            </div>
                                        </ContentTemplate> 
                                    </asp:UpdatePanel>
                                </div>
                            </td>
                            <td colspan="2"  class="CustomItem" valign="top">
                            <b>Description</b><hr />
                                {JobXDescription}
                            </td>
                        </tr>
                    </table>
                </div>
            </div> 
        </div>
        
        <div factory:activator="Tab|Pricing">
            <div factory:flow="NewRow" style="padding-top:8px;" xmlns:factory="urn:codeontime:app-factory"> 
                <div id="view4" runat="server">
                </div> 
                <aquarium:DataViewExtender id="DataViewExtender4" runat="server" TargetControlID="view4" Controller="Events" view="editForm2" ShowActionBar="false" ShowActionButtons="Top"/>
                <div id="Events_editForm2" style="display:none;">
                    <table style="width: 100%;" class="TabDetailsTable">
                        <tr class="TabDetailsTR">
                             <td colspan="3"><br /><b>Ticket Prices</b><hr /></td>
                        </tr>
                        <tr class="TabDetailsTR">
                            <td width="20%">Individual</td><td class="CustomItem" width="30%">{JobCode}</td>
                            <td width="50%"></td>
                        </tr>
                        <tr class="TabDetailsTR">
                            <td>Non-member Price (Excl GST)</td><td class="CustomItem">{StockPrice}</td>
                            <td></td>
                        </tr>
                        <tr class="TabDetailsTR">
                            <td>Member Price (Excl GST)</td><td class="CustomItem">{StockPriceMember}</td>
                            <td></td>
                        </tr>
                        <tr><td colspan="2"><br /></td></tr>
                    </table>               
                </div>
            </div>
            <div id="adonNotTemplate">
                <div factory:flow="NewRow" xmlns:factory="urn:codeontime:app-factory"> 
                    <div id="view5" runat="server">
                    </div> 
                    <aquarium:DataViewExtender id="DataViewExtender5" runat="server" TargetControlID="view5" Controller="StockItemsAddOns" view="grid1" 
                    ShowActionBar="true" FilterFields="X_ConfigCode" FilterSource="JobCodeVal" ShowQuickFind="false" ShowInSummary="false" PageSize="10"/>
                    <div id="StockItemsAddOns_createForm1" style="display: none;">
                        <table style="width: 100%; padding: 0 10px;" class="TabDetailsTable FieldWrapper Body">
                            <tr class="TabDetailsTR">
                                <td width="15%">Add On Template</td><td class="CustomItem" width="35%">{AddOnTemplate}</td>
                                <td width="15%"></td><td width="35%"></td>
                            </tr>
                            <tr class="TabDetailsTR">
                                 <td colspan="4"><br /><b>General</b><hr /></td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td>Product Code *</td><td class="CustomItem">{STOCKCODE}</td>
                                <td colspan="2"></td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td>Description</td><td class="CustomItem">{DESCRIPTION}</td>
                                <td colspan="2"></td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td>Non-member Price (Excl GST)</td><td class="CustomItem">{SELLPRICE1}</td>
                                <td>Member Price (Excl GST)</td><td class="CustomItem">{SELLPRICE2}</td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td>Event Seats</td><td class="CustomItem">{X_EventSeats}</td>
                                <td>Seats per Group</td><td class="CustomItem">{X_EventSeatsPerGroup}</td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td colspan="2" class="CustomItem"><span style="visibility: hidden;">{AddOnImage}</span></td>
                                <td colspan="2" class="CustomItem"><span style="visibility: hidden;">{IsUploading}</span></td>
                            </tr>
                            <tr class="TabDetailsTR">
                            <td colspan="2" valign="top" style="padding-right: 30px;">
                                <b>Add On Image</b><hr />
                                    <div style="text-align: left; height: 330px;"> 
                                    <asp:UpdatePanel ID="NewAddOnImageUploadPanel" runat="server">
                                        <ContentTemplate>
                                            <div>
                                                <asp:Image runat="server" ID="NewAddOnPreviewImageId" Width="350px" Height="275px" ImageUrl="~/Images/Temp/NoImage.jpg" ToolTip="No Image Availble" BorderStyle="Ridge" BorderWidth="5px" BorderColor="White"/>
                                            </div>
                                            <div style="left: -35px; padding-bottom: 5px;">
                                                <act:AsyncFileUpload runat="server" ID="NewAddOnImageUploadId" UploaderStyle="Modern" 
                                                    Visible="false" OnUploadedComplete="NewAddOnImageUploadId_OnUploadedComplete" Width="359px"
                                                    OnUploadedFileError="NewAddOnImageUploadId_OnUploadFileError" ThrobberID="imgLoaderNewAddOn" CompleteBackColor="White" />
                                            </div>
                                            <div>
                                                <asp:Button ID="NewAddOnUploadImageAction" runat="server" OnClick="NewAddOnUploadImageAction_OnClick" Text="Upload Image" />
                                                <asp:Image ID="imgLoaderNewAddOn" runat="server" ImageUrl="~/App_Themes/_Shared/loader.gif"/>
                                            </div>
                                            <div style="visibility: hidden;">
                                                <asp:Button ID="NewAddOnUploadImageActionHidden" runat="server" OnClick="NewAddOnUploadImageActionHidden_OnClick" Text="Hidden Button"/>
                                            </div>
                                        </ContentTemplate> 
                                    </asp:UpdatePanel>
                                </div>
                            </td>
                            <td colspan="2" class="CustomItem" valign="top">
                            <b>Description</b><hr />
                                {NOTES}
                            </td>
                        </tr>
                        </table>         
                    </div>

                    <div id="StockItemsAddOns_editForm1" style="display: none;">
                        <table style="width: 100%; padding: 0 10px;" class="TabDetailsTable FieldWrapper Body">
                            <tr class="TabDetailsTR">
                                 <td colspan="4"><br /><b>General</b><hr /></td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td width="15%">Product Code *</td><td width="35%" class="CustomItem">{TempStockCode}</td>
                                <td colspan="2"></td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td>Description</td><td class="CustomItem">{DESCRIPTION}</td>
                                <td colspan="2"><span style="visibility: hidden;">{OldImageName}</span></td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td>Non-member Price (Excl GST)</td><td class="CustomItem">{SELLPRICE1}</td>
                                <td width="15%">Member Price (Excl GST)</td><td width="35%" class="CustomItem">{SELLPRICE2}</td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td>Event Seats</td><td class="CustomItem">{X_EventSeats}</td>
                                <td>Seats per Group</td><td class="CustomItem">{X_EventSeatsPerGroup}</td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td colspan="2" class="CustomItem"><span style="visibility: hidden;">{AddOnImage}</span></td>
                                <td colspan="2" class="CustomItem"><span style="visibility: hidden;">{IsUploading}</span></td>
                            </tr>
                            <tr class="TabDetailsTR">
                            <td colspan="2" valign="top" style="padding-right: 30px;">
                                <b>Add On Image</b><hr />
                                 <div style="text-align: left; height: 330px;"> 
                                    <asp:UpdatePanel ID="EditAddOnImageUploadPanel" runat="server">
                                        <ContentTemplate>
                                            <div>
                                                <asp:Image runat="server" ID="EditAddOnPreviewImageId" Width="350px" Height="275px" ImageUrl="" ToolTip="" BorderStyle="Ridge" BorderWidth="5px" BorderColor="White"/>
                                                <asp:ImageButton ID="btnRemoveEditAddOn" runat="server" ImageUrl="~/App_Themes/_Shared/image_remove.png" 
                                                    Style="position: relative; top: -4px; left: -40px;" ToolTip="Remove Current Image" Visible="false" OnClick="btnRemoveEditAddOn_OnClick"/>
                                            </div>
                                            <div style="left: -35px; padding-bottom: 5px;">
                                                <act:AsyncFileUpload runat="server" ID="EditAddOnImageUploadId" UploaderStyle="Modern" 
                                                    Visible="false" OnUploadedComplete="EditAddOnImageUploadId_OnUploadedComplete" Width="359px"
                                                    OnUploadedFileError="EditAddOnImageUploadId_OnUploadFileError" ThrobberID="imgLoaderEditAddOn" CompleteBackColor="White" />
                                            </div>
                                            <div>
                                                <asp:Button ID="EditAddOnUploadImageAction" runat="server" OnClick="EditAddOnUploadImageAction_OnClick" Text="Edit Image" />
                                                <asp:Image ID="imgLoaderEditAddOn" runat="server" ImageUrl="~/App_Themes/_Shared/loader.gif"/>
                                            </div>
                                        </ContentTemplate> 
                                    </asp:UpdatePanel>
                                </div>
                            </td>
                            <td colspan="2" class="CustomItem" valign="top">
                            <b>Description</b><hr />
                                {NOTES}
                            </td>
                        </tr>
                        </table>         
                    </div>

                </div>
            </div>
            <div id="adonTemplate">
                <div factory:flow="NewRow" xmlns:factory="urn:codeontime:app-factory"> 
                    <div id="viewTemplate" runat="server"></div> 
                    <aquarium:DataViewExtender id="DataViewTemplate" runat="server" TargetControlID="viewTemplate" Controller="StockItemsAddOns" view="grid2" 
                    ShowActionBar="true" FilterFields="X_ConfigCode" FilterSource="JobCodeVal" ShowQuickFind="false" ShowInSummary="false" PageSize="10"/>
                </div>
            </div>
        </div>
        
        <div factory:activator="Tab|Email Template">
                <div factory:flow="NewRow" style="padding-top:8px;" xmlns:factory="urn:codeontime:app-factory"> 
                    <div id="viewEmailTemplate" runat="server">
                    </div>
                    <aquarium:DataViewExtender ID="EmailTemplateDataViewExtender" runat="server" TargetControlID="viewEmailTemplate"
                        Controller="X_EmailTemplate" View="editForm1" FilterSource="EventID" FilterFields="JobNo" ShowInSummary="false"/>
             </div>
        </div>
        
        <div factory:activator="Tab|Sponsor Template">
            <div factory:flow="NewRow" style="padding-top: 8px;" xmlns:factory="urn:codeontime:app-factory">
                <div id="viewSponsorTemplate" runat="server">
                </div>
                <aquarium:DataViewExtender ID="SponsorTemplateDataViewExtender" runat="server" TargetControlID="viewSponsorTemplate" 
                        Controller="X_SponsorTemplate" View="editForm1" FilterSource="EventID" FilterFields="JobNo" ShowInSummary="false"/>
            </div>
        </div>

        <div id="registrationsTab">
            <div factory:activator="Tab|Registrations">
                <div factory:flow="NewRow" style="padding-top:8px;" xmlns:factory="urn:codeontime:app-factory"> 
                    <div id="view2" runat="server">
                    </div>
                    <aquarium:DataViewExtender id="DataViewExtender2" runat="server" TargetControlID="view2" Controller="Registrations" view="grid1" ShowActionBar="true" FilterFields="JobNoGr" FilterSource="EventID" AutoSelectFirstRow="true" AutoHighlightFirstRow="true" PageSize="25"/>
                    
                    <div id="Registrations_createForm1" style="display:none;">                        
                        <table style="width: 100%; padding: 0 10px;" class="TabDetailsTable FieldWrapper Body">
                            <tr class="TabDetailsTR">
                                <td colspan="3" class="CustomItem InLine"><span style="visibility: hidden;">{TaxRate}</span></td>
                                <td class="CustomItem InLine" align="right">Total including GST: {TotalIncGST} 
                                    <br />Total excluding GST: {TotalExcGST}
                                </td>    
                            </tr>
                            <tr class="TabDetailsTR">
                                 <td colspan="4"><b>Details</b><hr /></td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td width="15%">Booking Date *</td><td class="CustomDateTime" width="30%">{BookingDate}</td>
                                <td width="15%"></td><td class="CustomItem" width="30%"></td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td>Booking Contact *</td><td class="CustomItem">{BookingContact}</td>
                                <td>Company Name</td><td class="CustomItem"><b>{CompanyNameHide}</b></td>
                            </tr>
         
                            <tr class="TabDetailsTR">
                                <td>Booking Email</td><td class="CustomItem">{BookingEmail}</td>
                                <td></td><td></td>
                            </tr>
                                
                            <tr class="TabDetailsTR">
                                <td>Purchase Order No.</td><td class="CustomItem">{PurchaseOrderNo}</td>
                                <td></td><td></td>
                            </tr>

                            <tr class="TabDetailsTR">
                                 <td colspan="4"><br /><b>Price</b><hr /></td>
                            </tr>
                            
                            <tr class="TabDetailsTR">
                                <td colspan="4">
                                    <table class="TabDetailsTable FieldWrapper Body" style="width: 100%; padding: 0 10px; background-color: #FFFFFF; border: 1px solid #C3C3C3; border-collapse: collapse;">
                                        <tr class="RegistrationTabHeader">
                                            <td style="width: 190px; color: #003399; text-align: center; height: 35px;">StockCode</td>
                                            <td style="text-align: center; color: #003399;">Description</td>
                                            <td style="width: 5px;"></td>
                                            <td style="width: 120px; text-align: center; color: #003399;">Charged Quantity</td>
                                            <td style="width: 120px; text-align: center; color: #003399;">Complimentary Quantity</td>
                                            <td style="width: 150px; text-align: center; color: #003399;" class="CustomItem">
                                                <b>{PriceType}</b> (Excl GST)
                                            </td>
                                            <td style="width: 5px;"></td>
                                            <td style="width: 120px; text-align: center; color: #003399;">Total Charge</td>
                                            <td style="width: 5px;"></td>
                                        </tr>
                                        <tr class="TabDetailsTR ProductList" style="font-weight: bold;">
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3;  border-left: 1px solid #FFFFFF;">{StockCode1}</td>
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3; border-right: none;">{PriceDescription1}</td>
                                            <td class="CustomItem Cell" style="border: 1px solid #C3C3C3; border-left: none;"><div style="visibility: hidden;">{EventSeatsPerGroup1}</div></td>
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3;">{GroupQtyCharged1}</td>
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3;">{GroupQtyFree1}</td>
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3; border-right: none;">{Price1}</td>
                                            <td class="CustomItem Cell" style="border: 1px solid #C3C3C3; border-left: none;"><div style="visibility: hidden;">{Quantity1}</div></td>
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3; border-right: none;">{TotalCharge1}</td>
                                            <td class="CustomItem Cell" style="border: 1px solid #C3C3C3; border-left: none;"><div style="visibility: hidden;">{ComplimentaryQuantity1}</div></td>
                                        </tr>
                                        <%  
                                            string className = null;
                                            int i; 
                                            for (i = 2; i <= (Convert.ToInt32(CountPrice.Value) + 1); i++) 
                                            {
                                                className = (i % 2 == 0) ? "AlternatingRow" : "Row";
                                        %>
                                        <tr class="TabDetailsTR <%=className%> ProductList">
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3; border-left: 1px solid #FFFFFF;">{StockCode<%=i.ToString()%>}</td>
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3; border-right: none; border-right: none;">{PriceDescription<%=i.ToString()%>}</td>
                                            <td class="CustomItem Cell" style="border: 1px solid #C3C3C3; border-left: none;"><div style="visibility: hidden;">{EventSeatsPerGroup<%=i.ToString()%>}</div></td>
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3;">{GroupQtyCharged<%=i.ToString()%>}</td>
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3;">{GroupQtyFree<%=i.ToString()%>}</td>
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3; border-right: none;">{Price<%=i.ToString()%>}</td>
                                            <td class="CustomItem Cell" style="border: 1px solid #C3C3C3; border-left: none;"><div style="visibility: hidden;">{Quantity<%=i.ToString()%>}</div></td>
                                            <td class="CustomItem Cell" style="padding: 4px; border: 1px solid #C3C3C3; border-right: none;">{TotalCharge<%=i.ToString()%>}</td>
                                            <td class="CustomItem Cell" style="border: 1px solid #C3C3C3; border-left: none;"><div style="visibility: hidden;">{ComplimentaryQuantity<%=i.ToString()%>}</div></td>
                                        </tr>
                                        <%}%>                                       
                                    </table>
                                </td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td colspan="2" class="CustomItem"><span style="visibility: hidden;">{RowCount}</span></td>
                                <td class="CustomItem">
                                    <span style="visibility: hidden;">{ProductHasQtyPosition}
                                    </span>
                                </td>
                                <td class="CustomItem">
                                    <span style="visibility: hidden;">{ProductHasQtyCount}
                                    </span>
                                </td>
                            </tr>

                            <tr class="TabDetailsTR">
                                 <td colspan="4" class="CustomItem"><b>{AttendeesWarning}</b><hr /></td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td colspan="4">
                                    <div style="height: 385px; overflow: auto; background-color: White; border: 1px solid #6F9DD9;" id="attedeeContainer">
                                        <table class="TabDetailsTable FieldWrapper Body" id="attendeeTable" style="width: 100%; padding: 0 10px; background-color: #FFFFFF; border: 1px solid #C3C3C3; border-collapse: collapse;">
                                            <tr class="RegistrationTabHeader"> 
                                                <td style="width: 24px; height: 35px;"></td>
                                                <td style="width: 190px; text-align: center; color: #003399;">Name</td>
                                                <td style="text-align: center; color: #003399;">Company</td>
                                                <% for (i = 1; i <= (Convert.ToInt32(CountPrice.Value) + 1); i++) %>
                                                <%{%>
                                                <td class="CustomItem" style="width: 50px; text-align: center; color: #003399;">
                                                    <%if (i == 1) {%>
                                                        <b>{StockCode<%=i.ToString()%>}</b>
                                                    <%} else {%>
                                                        {StockCode<%=i.ToString()%>}
                                                    <% }%>
                                                </td>
                                                <%}%>
                                            </tr>
                                            <% for (i = 1; i <= 50; i++) 
                                            {
                                                className = (i % 2 == 0) ? "AlternatingRow" : "Row";
                                            %>
                                           <tr class="TabDetailsTR <%=className%>" row-order="<%=i.ToString() %>">
                                                <td class="Cell" align="center"  style="border:1px solid #C3C3C3; border-right: none; width: 24px; color: Red; border-left: 1px solid #FFFFFF;"><b><%=i.ToString()%></b></td>
                                                <td class="CustomItem Cell" style="border:1px solid #C3C3C3; border-left: none; padding-left:7px;">{Attendee<%=i.ToString()%>}</td>
                                                <td class="CustomItem Cell" style="border:1px solid #C3C3C3; padding-left:7px;">{AttendeeCompanyName<%=i.ToString()%>}</td>
                                                <% for (int j = 1; j <= (Convert.ToInt32(CountPrice.Value) + 1); j++) %>
                                                <%{%>
                                                <td class="CustomItem Cell" style="border:1px solid #C3C3C3; padding-left:7px; text-align: center;">{Att<%=i.ToString()%>StockCode<%=j.ToString()%>}</td>
                                                <%}%>
                                            </tr>
                                            <%}%>
                                            <tr class="RegistrationTabHeader"> 
                                                <td style="width: 24px; height: 35px; text-align: center;"><a href="#" id="attendees-add-btn" title="Add More Attendees" class="addMoreAtt"><asp:Image runat="server" ImageUrl="~/App_Themes/_Shared/add_att.png" Height="26px" Width="26px"/></a></td>
                                                <td style="width: 190px; text-align: center; color: #003399;">Name</td>
                                                <td style="text-align: center; color: #003399;">Company</td>
                                                <% for (i = 1; i <= (Convert.ToInt32(CountPrice.Value) + 1); i++) %>
                                                <%{%>
                                                <td class="CustomItem" style="width: 50px; text-align: center; color: #003399;">
                                                    <%if (i == 1) {%>
                                                        <b>{StockCode<%=i.ToString()%>}</b>
                                                    <%} else {%>
                                                        {StockCode<%=i.ToString()%>}
                                                    <% }%>
                                                </td>
                                                <%}%>
                                            </tr>                                           
                                        </table>
                                    </div> 
                                </td>
                            </tr>
                            <tr class="TabDetailsTR">
                                 <td colspan="4"><br /><b>Invoicing</b><hr /></td>
                            </tr>
                            <tr class="TabDetailsTR">
                                <td>Payment Method</td><td class="CustomItem">{PaymentMethod}</td>
                                <td>Confirmation Code</td><td class="CustomItem">{ConfirmationCode}</td>
                            </tr>
                        </table>
                    </div>
                    
                </div>
                <div factory:flow="NewRow" style="padding-top:8px" xmlns:factory="urn:codeontime:app-factory">
                    <div id="viewAttendees" runat="server">
                    </div>
                    <aquarium:DataViewExtender id="DataViewExtender8" runat="server" TargetControlID="viewAttendees" Controller="Attendees" FilterFields="JoinField" FilterSource="DataViewExtender2" AutoHide="Container" VisibleWhen="[Master.FormName] != 'EDIT'" PageSize="25"/>
                </div>
                <div factory:flow="NewRow" style="padding-top:8px" xmlns:factory="urn:codeontime:app-factory">
                    <div id="viewInvoiceBelongToRegistration" runat="server">
                    </div>
                    <aquarium:DataViewExtender id="DataViewInvoices" runat="server" TargetControlID="viewInvoiceBelongToRegistration" Controller="Invoices" View="grid2" FilterFields="InvNoGr" FilterSource="DataViewExtender2" AutoHide="Container" VisibleWhen="[Master.FormName] != 'EDIT'" PageSize="25"/>
                </div>
            </div>
        </div>
        
        <div id="attendeesTab">
            <div factory:activator="Tab|Attendees">
                    <div factory:flow="NewRow" style="padding-top:8px;" xmlns:factory="urn:codeontime:app-factory"> 
                        <div id="viewallAttendees" runat="server">
                        </div>
                        <aquarium:DataViewExtender id="DataViewExtender9" runat="server" TargetControlID="viewAllAttendees" Controller="Attendees" FilterFields="JobNo" FilterSource="EventID" View="grid2" AutoSelectFirstRow="true" PageSize="25"/>
                 </div>
            </div>
        </div>
        
        <div id="invoiceTab">
            <div factory:activator="Tab|Invoices">
                <div factory:flow="NewRow" style="padding-top:8px;" xmlns:factory="urn:codeontime:app-factory"> 
                    <div id="view6" runat="server">
                    </div>
                    <aquarium:DataViewExtender ID="DataViewExtender6" runat="server" TargetControlID="view6"
                        Controller="Invoices" View="grid1" FilterSource="EventID" FilterFields="JobNo" ShowInSummary="false" PageSize="25"/>
                </div>
            </div>
        </div>
        
        <div id="budgetTab">
            <div factory:activator="Tab|Budgets">
                <div factory:flow="NewRow" style="padding-top:8px;" xmlns:factory="urn:codeontime:app-factory"> 
                    <div id="view3" runat="server">
                    </div>
                    <aquarium:DataViewExtender id="DataViewExtender3" runat="server" TargetControlID="view3" Controller="JOBCOST_LINES" view="grid1" FilterFields="JOBNO" FilterSource="EventID" AutoSelectFirstRow="true" AutoHighlightFirstRow="true"/>
                </div>
                <div factory:flow="NewRow" style="padding-top:8px;" xmlns:factory="urn:codeontime:app-factory"> 
                    <div id="viewExpenses" runat="server">
                    </div>
                    <aquarium:DataViewExtender id="DataViewExtender7" runat="server" TargetControlID="viewExpenses" Controller="JOB_TRANSACTIONS" view="grid1" FilterFields="JOBNO" FilterSource="EventID" AutoSelectFirstRow="true" AutoHighlightFirstRow="true"/>
                </div>
                <table width="100%">
                    <tr><td width="58%"></td><td></td><td align="right"></td></tr>
                    <tr><td align="right"><b>Profit/(Loss)</b></td><td colspan="2" align="center"><b><span id="profit"></span></b></td></tr>
                </table>
            </div>
        </div>
              
    </div>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="SideBarPlaceHolder" runat="Server">
    <div class="TaskBox About">
        <div class="Inner">
            <div class="Header">
                About</div>
            <div class="Value">
                This page allows to mamage event details.</div>
        </div>
    </div>
</asp:Content>
