using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HeadMovementBasic : MonoBehaviour
{
    public float sensitivity = 2.0f; // Mouse sensitivity
    public Transform head; // Reference to the player's head transform

    private float rotationX = 0;

    [System.NonSerialized] public bool InventoryLock;
    
    void Start()
    {
        InventoryLock = false;
        Cursor.lockState = CursorLockMode.Locked; // Lock the cursor to the center of the screen
    }

    void Update()
    {
        if(!InventoryLock)
        {
            Cursor.lockState = CursorLockMode.Locked;
            MoveHead();
        }
        else
        {
            Cursor.lockState = CursorLockMode.Confined;
            Cursor.visible = true;
        }
    }

    private void MoveHead()
    {
        // Get mouse input
        float mouseX = Input.GetAxis("Mouse X");
        float mouseY = Input.GetAxis("Mouse Y");

        // Calculate rotation amount
        rotationX -= mouseY * sensitivity;
        rotationX = Mathf.Clamp(rotationX, -90f, 90f); // Limit vertical rotation

        // Apply rotations to the head and body separately
        head.localRotation = Quaternion.Euler(rotationX, 0, 0);
        transform.Rotate(Vector3.up * mouseX * sensitivity);
    }
}

