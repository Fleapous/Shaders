using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting.FullSerializer;
using UnityEngine;
using UnityEngine.UIElements;
using Cursor = UnityEngine.UIElements.Cursor;

public class ToggleInventory : MonoBehaviour
{
    public float interactionDistace;

    public VisualTreeAsset ItemTemplate;
    public UIDocument InventoryUI;
    
    private Inventory _inventory;
    private Camera _playerCam;
    private HeadMovementBasic _headMovementBasic;

    private bool _inventoryMenuOpen = false;
    private bool _otherMenuOpen = false;
    private void Start()
    {
        _inventory = GetComponent<Inventory>();
        _playerCam = Camera.main;
        _headMovementBasic = GetComponent<HeadMovementBasic>();

        InventoryUI.rootVisualElement.Q("RowL").visible = false;
        InventoryUI.rootVisualElement.Q("RowR").visible = false;
    }

    private void Update()
    {
        // bring up player inventory
        if (Input.GetKeyDown(KeyCode.E))
        {
            _inventoryMenuOpen = !_inventoryMenuOpen;
            UIEnableDisable(InventoryUI, _inventory, "RowL");
        }

        if (Input.GetKeyDown(KeyCode.F))
        {
            var inv = PerformRaycast();
            if (inv != null)
            {
                _otherMenuOpen = !_otherMenuOpen;
                UIEnableDisable(InventoryUI, inv, "RowR");
            }
        }

        // Determine if any menu is open
        bool anyMenuOpen = _inventoryMenuOpen || _otherMenuOpen;

        // Set InventoryLock based on menu state
        _headMovementBasic.InventoryLock = anyMenuOpen;
    }

    private void UIEnableDisable(UIDocument uiDocument, Inventory inventory, string uiContainer)
    {
        uiDocument.rootVisualElement.Q(uiContainer).visible = !uiDocument.rootVisualElement.Q(uiContainer).visible;
        if (uiDocument.rootVisualElement.Q(uiContainer).visible)
        {
            _headMovementBasic.InventoryLock = true;
            inventory.ShowItems(uiDocument, ItemTemplate, uiContainer);
        }
        else
        {
            _headMovementBasic.InventoryLock = false;
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
