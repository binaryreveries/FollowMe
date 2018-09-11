using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public float smooth;
    public float moveMultiplier;
    public float turnMultiplier;

    private Rigidbody2D rb;
    private Transform tf;

    private void Start()
    {
        rb = GetComponent<Rigidbody2D>();
        tf = GetComponent<Transform>();
    }

    void Update()
    {
        
    }
    void FixedUpdate()
    {

        float acceleration = Input.GetAxis("Vertical");
        float rotation = Input.GetAxis("Horizontal");

        Quaternion turn = Quaternion.Euler(0, 0, z: turnMultiplier * -rotation);

        Quaternion target = tf.rotation * turn;

        tf.rotation = Quaternion.Slerp(tf.rotation, target, Time.deltaTime * smooth);

        rb.velocity = transform.up * (moveMultiplier * acceleration);

    }


}
