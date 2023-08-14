using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UIElements;

public class Inventory_Manager : MonoBehaviour
{
    [DoNotSerialize]
    public UIDocument uiInventory;
    public VisualTreeAsset buttonTemplate;
    private void OnEnable()
    {
        uiInventory = GetComponent<UIDocument>();
        TemplateContainer buttonContainer = buttonTemplate.Instantiate();
        uiInventory.rootVisualElement.Q("ItemRow").Add(buttonContainer);
        
    }
}
