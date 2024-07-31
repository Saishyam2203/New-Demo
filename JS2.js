import { LightningElement, wire, track } from 'lwc';
import getOrderProducts from '@salesforce/apex/OrderAndOrderProductRentedDetail.orderProductDetail';
import getOrders from '@salesforce/apex/OrderAndOrderProductRentedDetail.orderDetails';
import getContractDetails from '@salesforce/apex/OrderAndOrderProductRentedDetail.contractRec';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { CurrentPageReference } from 'lightning/navigation';
import ORDERITEM_OBJECT from '@salesforce/schema/OrderItem';
import STATUS_FIELD from '@salesforce/schema/OrderItem.Rental_Status__c';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';

// columns
const columns = [
    {
        label: 'Order Product Number',
        fieldName: 'OrderItemNumber',
        type: 'text',
    },
    {
        label: 'Rental Start Date',
        fieldName: 'Rental_start_date1__c',
        type: 'date',
    },
    {
        label: 'Rental End Date',
        fieldName: 'Rental_End_Date__c',
        type: 'date',
        editable: true,
    }, {
        label: 'Rental Status', fieldName: 'Rental_Status__c', type: 'picklistColumn', editable: true, typeAttributes: {
            placeholder: 'Choose Status', options: { fieldName: 'pickListOptions' },
            value: { fieldName: 'Rental_Status__c' },
            context: { fieldName: 'Id' }
        }
    },
    {
        label: 'Net Total Price',
        fieldName: 'NetTotalPrice',
        type: 'currency',
    }
];

const columns2 = [
    {
        label: 'Order Name',
        fieldName: 'Name',
        type: 'text',
    }, {
        label: 'Order start Date',
        fieldName: 'EffectiveDate',
        type: 'date',
    }, {
        label: 'Order End Date',
        fieldName: 'EndDate',
        type: 'date',
    }, {
        label: 'Status',
        fieldName: 'Status',
        type: 'text',
    }, {
        label: 'Order Amount',
        fieldName: 'TotalAmount',
        type: 'currency',
    }
];

const columns3 = [
    {
        label: 'Contract Number',
        fieldName: 'ContractNumber',
        type: 'text',
    },
    {
        label: 'Contract Start Date',
        fieldName: 'StartDate',
        type: 'date',
    }, {
        label: 'Contract End Date',
        fieldName: 'EndDate',
        type: 'date',
    },
    {
        label: 'Status',
        fieldName: 'Status',
        type: 'text',
    },
];

export default class OrderProductReturnEquipment extends LightningElement {
    recId;
    @track orderProducts;
    @track orderRec;
    @track contractRec;
    columns = columns;
    columns2 = columns2;
    columns3 = columns3;
    saveDraftValues = [];
    productModalScreen = false;
    @track selectedRows = [];
    @track spinnerVisible = false;
    selectedRowsId;
    @track orderprdtData;
    @track draftValues = [];
    lastSavedData = [];
    @track pickListOptions;
    @track data = [];
    @track accountData;
    masterRecType = '012000000000000AAA';

    updatedRecordIds;
    @wire(CurrentPageReference) getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recId = currentPageReference.state.recordId;
        }
    }

    @wire(getOrders, { accntId: '$recId' })
    wireOrderProductRecords(results) {
        this.wiredOrderResult = results;
        if (results.data) {
            this.orderRec = results.data;
            console.log('this.orderRec', JSON.stringify(this.orderRec));
            this.error = undefined;
        } else if (results.error) {
            this.orderRec = undefined;
            this.error = results.error;
            this.showToast('Error', 'An Error Occurred!', 'error', 'dismissable');
        }
    }
    @wire(getObjectInfo, { objectApiName: ORDERITEM_OBJECT })
    objectInfo;

    //fetch picklist options
    @wire(getPicklistValues, {
        recordTypeId: "$masterRecType",
        fieldApiName: STATUS_FIELD
    })
    wirePickList({ error, data }) {
        if (data) {
            this.pickListOptions = data.values;
        } else if (error) {
            console.log(error);
        }
    }
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
        if (this.selectedRows.length > 1) {
            this.selectedRows = this.selectedRows.slice(0, 1);
            this.showNotification();
            event.preventDefault();
            return;
        }
        this.selectedRowsId = this.selectedRows[0]?.Id;
        this.selectedConId = this.selectedRows[0]?.ContractId;
        if (this.selectedRowsId && this.selectedConId) {
            this.fetchAccountDetails(this.selectedRowsId, this.pickListOptions);
        }
    }
    showNotification() {
        const event = new ShowToastEvent({
            title: 'Error',
            message: 'Only one row can be selected',
            variant: 'warning',
            mode: 'pester'
        });
        this.dispatchEvent(event);
    }

    handleNext() {
        if (this.selectedRows.length === 0) {
            this.showToast('Error', 'An Error Occurred!', 'error', 'dismissable');
            return;
        }
        this.productModalScreen = true;
    }

    fetchAccountDetails(selectedId, pickOptions) {
        getOrderProducts({ strOrderId: selectedId, pickList: pickOptions })
            .then(result => {
                console.log('result' + JSON.stringify(result));
                this.accountdata = result;
                this.data = JSON.parse(JSON.stringify(result));

                this.data.forEach(ele => {
                    ele.pickListOptions = this.pickListOptions;
                })

                this.lastSavedData = JSON.parse(JSON.stringify(this.data));

            }).catch(error => {
                this.data = undefined;
            });

        getContractDetails({ strContractId: this.selectedConId })
            .then(result => {
                this.contractRec = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.contractRec = undefined;
                this.showToast('Error', 'An Error Occurred!', 'error', 'dismissable');
            });
    }
    updateDataValues(updateItem) {
        let copyData = JSON.parse(JSON.stringify(this.data));

        copyData.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });

        //write changes back to original data
        this.data = [...copyData];
    }
    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];
        //store changed value to do operations
        //on save. This will enable inline editing &
        //show standard cancel & save button
        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });

        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }
    //handler to handle cell changes & update values in draft values
    handleCellChange(event) {
        let draftValues = event.detail.draftValues;
        draftValues.forEach(ele => {
            this.updateDraftValues(ele);
        })
    }
    async handleSave(event) {
        this.spinnerVisible = true;
        this.saveDraftValues = event.detail.draftValues;
        const recordInputs = this.saveDraftValues.map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });

        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        try {
            const results = await Promise.all(promises);
            this.showToast('Success', 'Records Updated Successfully!', 'success', 'dismissable');
            this.draftValues = [];
            await this.refresh();
        } catch (error) {
            this.showToast('Error', 'An Error Occurred!!', 'error', 'dismissable');
        } finally {
            this.draftValues = [];
            this.showSpinner = false;
            this.fetchAccountDetails(this.selectedRowsId, this.pickListOptions);
        }
    }
    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    async refresh() {
        await refreshApex(this.wiredOrderResult);
    }
}
Collapse












