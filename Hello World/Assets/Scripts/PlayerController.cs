using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public float smooth;
    public float moveMultiplier;
    public float turnMultiplier;
    public float roadPush;
    public Object newRoad;
    public Object oldRoad;

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

        Quaternion turnDelta = Quaternion.Euler(0, 0, z: turnMultiplier * -rotation);
        Quaternion targetAngle = tf.rotation * turnDelta;

        tf.rotation = Quaternion.Slerp(tf.rotation, targetAngle, Time.deltaTime * smooth);
        rb.velocity = transform.up * (moveMultiplier * acceleration);
    }

    void OnTriggerEnter2D(Collider2D other)
    {
        if(other.gameObject.CompareTag("RoadFrontier"))
        {
            Vector3 oldRoadPossition = other.transform.position;
            Vector3 currentPosition = tf.position;
            Vector3 newPosition = currentPosition + new Vector3(0.0f, roadPush, 0.0f);

            Quaternion oldRoadAngle = other.transform.rotation;
            Quaternion currentAngle = tf.rotation;



            Instantiate(oldRoad, oldRoadPossition, oldRoadAngle);
            Instantiate(newRoad, newPosition, currentAngle);

            other.gameObject.SetActive(false);
        }
    }
    


}
