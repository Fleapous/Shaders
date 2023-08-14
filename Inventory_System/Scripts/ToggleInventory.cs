using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public class ToggleInventory : MonoBehaviour
{
    public Inventory_Manager UI;
    
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
        UI.uiInventory.rootVisualElement.visible = !UI.uiInventory.rootVisualElement.visible;
    }
}
