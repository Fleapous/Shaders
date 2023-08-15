using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public class ToggleInventory : MonoBehaviour
{
    public VisualTreeAsset ItemTemplate;
    public UIDocument InventoryUI;
    private Inventory _inventory;
    private void Start()
    {
        _inventory = GetComponent<Inventory>();
    }

    private void Update()
    {
        // Check for key press
        if (Input.GetKeyDown(KeyCode.E))
        {
            UIEnableDisable();
        }
    }

    private void UIEnableDisable()
    {
        InventoryUI.rootVisualElement.visible = !InventoryUI.rootVisualElement.visible;
        if (InventoryUI.rootVisualElement.visible)
        {
            _inventory.ShowItems(InventoryUI, ItemTemplate);
        }
        else
        {
            _inventory.HideItems(InventoryUI);
        }
    }
}
