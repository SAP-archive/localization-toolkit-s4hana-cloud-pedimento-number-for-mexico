* Code provided @ SAP-samples - https://github.com/SAP-samples/localization-toolkit-s4hana-cloud-pedimento-number-for-mexico/
* This code is part of the blog post Localization Toolkit for SAP S/4HANA Cloud: Provide the Pedimento Number (Mexico) on e-Document using Custom Logic
* blog post @ https://blogs.sap.com/2020/09/07/provide-the-pedi…ing-custom-logic/
* published @ Localization Toolkit for SAP S/4HANA Cloud community - https://community.sap.com/topics/localization-toolkit-s4hana-cloud

DATA: lv_billingdocumenttype TYPE i_billingdocument-billingdocumenttype.

DATA: ls_pedimento TYPE edoc_mx_badi_customsdata_tab.
DATA: ls_custom_data TYPE edoc_mx_badi_customsdata_ouput.
DATA: lv_pedimento              TYPE i_clfnobjectcharcvalforkeydate-charcvalue,
      lv_clfnobjectinternalid   TYPE i_batch-clfnobjectinternalid,
      lv_accountingdocument     TYPE i_journalentryitem-accountingdocument,
      lv_accountingdocumentitem TYPE i_journalentryitem-accountingdocumentitem.

TYPES: BEGIN OF t_productplant,
         batch   TYPE i_goodsmovementcube-batch,
         product TYPE i_journalentryitem-product,
         plant   TYPE i_journalentryitem-plant,
       END OF t_productplant.

DATA: it_productplant TYPE STANDARD TABLE OF t_productplant ,      "itab
      wa_productplant TYPE t_productplant.


CLEAR ct_pediment_data.

IF sy-subrc = 0.

*Identify batch, product and plant from the journal entry item view and goods movement view. We use the following filter criterias:
*referencedocument, that is the billing document
*referencedocumentitem, that is the billing document item
*accounting document type 'RV', that is the journal entry item relevant for billing
*ledger 'OL' being the leading ledger
*referencedocument item not null
*Save the item records into the structure wa_productplant

  SELECT SINGLE  g~batch, j~product, j~plant
         FROM i_goodsmovementcube AS g INNER JOIN i_billingdocumentitem AS b
                                             ON g~deliverydocument = b~referencesddocument
                                             AND g~deliverydocumentitem = b~referencesddocumentitem
                                       INNER JOIN i_journalentryitem AS j
                                             ON b~billingdocument = j~referencedocument
                                             AND b~billingdocumentitem = j~referencedocumentitem
         WHERE j~referencedocument = @is_source-salesdocumentnum
         AND j~referencedocumentitem = @is_source-salesdocitemnum
         AND j~accountingdocumenttype = 'RV'
         AND j~ledger = '0L'
         AND j~referencedocumentitem NE '000000'
         INTO CORRESPONDING FIELDS OF @wa_productplant.

*Identify clfnobjectinternalid from the batch view specific for the batch, product and plant saved in the wa_productplant structure. We use the following filter criterias:
*material
*batch
*plant
*and we save the data into a local variable lv_clfnobjectinternalid

  SELECT SINGLE clfnobjectinternalid
                FROM i_batch
                WHERE
                material = @wa_productplant-product
                AND plant = @wa_productplant-plant
                AND batch = @wa_productplant-batch
                INTO @lv_clfnobjectinternalid.
*Pedimento
*Identify pedimento numbers saved in the charcvalue field from the i_clfnobjectcharcvalforkeydate. We use the following parameters:
*p_keydate which is the current system date
*and the following filters:
*clfnobjectinternalid
*characteristic name from the association \_characteristic. This is the name of the batch characteristic saved by the BOM_ENGINEER.
  SELECT SINGLE charcvalue
                  FROM i_clfnobjectcharcvalforkeydate( p_keydate = @sy-datum )
                  WHERE
                  clfnobjectinternalid = @lv_clfnobjectinternalid
                  AND \_characteristic-characteristic = 'PEDIMENTO'
                  INTO @lv_pedimento.


*Fill the ct_pediment_data output parameter with the pedimento number identified previously.

  ls_custom_data-pediment_num = lv_pedimento.

  APPEND ls_custom_data TO ct_pediment_data.


ENDIF.
