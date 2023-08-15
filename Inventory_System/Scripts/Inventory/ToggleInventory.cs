using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public class ToggleInventory : MonoBehaviour
{
    public float interactionDistace;

    public VisualTreeAsset ItemTemplate;
    public UIDocument InventoryUI;
    
    private Inventory _inventory;
    private Camera _playerCam;
    private void Start()
    {
        _inventory = GetComponent<Inventory>();
        _playerCam = Camera.main;
    }

    private void Update()
    {
        // bring up player inventory
        if (Input.GetKeyDown(KeyCode.E))
        {
            UIEnableDisable(InventoryUI, _inventory, "RowL");
        }

        if (Input.GetKeyDown(KeyCode.F))
        {
            var inv = PerformRaycast();
            if(inv != null)
                UIEnableDisable(InventoryUI, inv, "RowR");
        }
    }

    private void UIEnableDisable(UIDocument uiDocument, Inventory inventory, string uiContainer)
    {
        uiDocument.rootVisualElement.Q(uiContainer).visible = !uiDocument.rootVisualElement.Q(uiContainer).visible;
        if (uiDocument.rootVisualElement.Q(uiContainer).visible)
        {
            inventory.ShowItems(uiDocument, ItemTemplate, uiContainer);
        }
        else
        {
            inventory.HideItems(InventoryUI, uiContainer);
        }
    }
    
    private Inventory PerformRaycast()
    {
        RaycastHit hit;
        Ray ray = _playerCam.ScreenPointToRay(new Vector3(Screen.width / 2, Screen.height / 2, 0));

        if (Physics.Raycast(ray, out hit, interactionDistace))
        {
            GameObject hitObject = hit.collider.gameObject;
            if (!hitObject.CompareTag("Chest"))
                return null;
            return hitObject.GetComponent<Inventory>();
        }
        
        return null;
    }
}
