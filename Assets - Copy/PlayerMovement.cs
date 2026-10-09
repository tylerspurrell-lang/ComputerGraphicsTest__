using Unity.VisualScripting;
using UnityEngine;

public class Movement : MonoBehaviour
{
    Rigidbody2D body;

    [Header("Car Movement Settings")]
    [SerializeField] float accelerationPower = 5f;
    [SerializeField] float steeringPower = 1.5f;
    [SerializeField] float driftPower = 0.5f;
    [SerializeField] float maxSpeedOnRoad = 10f;
    [SerializeField] float maxSpeedOffRoad = 5f;
    [SerializeField] float maxSpeedWhileDrifting = 15f;
    [SerializeField] float maxSpeedWithBoost = 20f;

    [Header("Boost Settings")]
    [SerializeField] float boostForce = 15f;
    [SerializeField] float boostHoldTimeRequired = 5f; // Hold for 5 seconds to activate

    [Header("Effects")]
    [SerializeField] ParticleSystem driftParticles;

    float maxSpeed;
    float accelerationInput;
    float rotationAngle;
    float velocityVsUp;
    float horizontalInput;
    float steeringInput;

    bool offRoad;
    bool isDrifting;
    bool driftActivated;

    // Boost tracking
    float boostHoldTime = 0f;
    bool boostReady = false;

    void Start()
    {
        body = GetComponent<Rigidbody2D>();
        body.gravityScale = 0;
        maxSpeed = maxSpeedOnRoad;

        if (driftParticles != null)
            driftParticles.gameObject.SetActive(false);
    }

    void Update()
    {
        horizontalInput = Input.GetAxis("Horizontal");
        accelerationInput = Input.GetAxis("Vertical");

        // Drift input
        if (Input.GetKeyDown(KeyCode.Space))
            isDrifting = true;
        if (Input.GetKeyUp(KeyCode.Space))
            isDrifting = false;

        // Boost hold logic
        if (Input.GetKey(KeyCode.LeftShift))
        {
            boostHoldTime += Time.deltaTime;

            if (boostHoldTime >= boostHoldTimeRequired && !boostReady)
            {
                boostReady = true;

                // Turn particles yellow
                if (driftParticles != null)
                {
                    var main = driftParticles.main;
                    main.startColor = Color.yellow;
                    driftParticles.gameObject.SetActive(true);
                }
            }
        }

        if (Input.GetKeyUp(KeyCode.LeftShift))
        {
            if (boostReady)
            {
                ApplySpeedBoost();
            }

            // Reset
            boostHoldTime = 0f;
            boostReady = false;

            if (driftParticles != null)
                driftParticles.gameObject.SetActive(false);
        }

        // Grey particles when drifting but boost not ready
        if (driftActivated && driftParticles != null && !boostReady)
        {
            var main = driftParticles.main;
            main.startColor = Color.grey;
            driftParticles.gameObject.SetActive(true);
        }
    }

    void FixedUpdate()
    {
        ApplySteering();
        ApplyEngineForce();
        KillOrthogonalVelocity();

        if (velocityVsUp > maxSpeed)
            SlowDownToMaxSpeed();

        if (isDrifting && steeringInput != 0 && !driftActivated)
            ActivateDrift();
        else if ((!isDrifting || steeringInput == 0) && driftActivated)
            DeactivateDrift();
    }

    public void ApplySpeedBoost()
    {
        // Apply instant boost
        body.AddForce(transform.up * boostForce, ForceMode2D.Impulse);
        maxSpeed = maxSpeedWithBoost;
    }

    void ActivateDrift()
    {
        driftPower = 0.9f;
        steeringPower = 2.5f;
        driftActivated = true;
    }

    void DeactivateDrift()
    {
        driftPower = 0.5f;
        steeringPower = 1.5f;
        driftActivated = false;
        if (driftParticles != null)
            driftParticles.gameObject.SetActive(false);
    }

    void ApplySteering()
    {
        if (horizontalInput < 0 && steeringInput > 0 && ((accelerationInput <= 0 && velocityVsUp > 0) || (accelerationInput >= 0 && velocityVsUp < 0)))
            steeringInput = Mathf.Lerp(steeringInput, -1, Time.fixedDeltaTime);
        else if (horizontalInput > 0 && steeringInput < 0 && ((accelerationInput <= 0 && velocityVsUp > 0) || (accelerationInput >= 0 && velocityVsUp < 0)))
            steeringInput = Mathf.Lerp(steeringInput, 1, Time.fixedDeltaTime);
        else
            steeringInput = horizontalInput;

        float minSpeedForTurn = Mathf.Clamp01(body.linearVelocity.magnitude / 8f);

        if ((accelerationInput <= 0 && velocityVsUp > 0) || (accelerationInput >= 0 && velocityVsUp < 0))
            steeringPower = Mathf.Lerp(steeringPower, 0.0f, Time.fixedDeltaTime * 2);
        else
            steeringPower = driftActivated ? 2.5f : 1.5f;

        if (velocityVsUp <= 0)
            rotationAngle += steeringInput * steeringPower * minSpeedForTurn;
        else
            rotationAngle -= steeringInput * steeringPower * minSpeedForTurn;

        body.rotation = rotationAngle;
    }

    void ApplyEngineForce()
    {
        velocityVsUp = Vector2.Dot(transform.up, body.linearVelocity);

        if (velocityVsUp >= maxSpeed && accelerationInput > 0) return;
        if (velocityVsUp <= -maxSpeed * 0.5f && accelerationInput < 0) return;

        body.linearDamping = (accelerationInput == 0 || (accelerationInput < 0 && velocityVsUp > 0)) ? 5f : 0f;

        Vector2 engineForce = transform.up * accelerationInput * accelerationPower;
        body.AddForce(engineForce, ForceMode2D.Force);
    }

    void KillOrthogonalVelocity()
    {
        Vector2 forwardVelocity = transform.up * Vector2.Dot(body.linearVelocity, transform.up);
        Vector2 rightVelocity = transform.right * Vector2.Dot(body.linearVelocity, transform.right);

        body.linearVelocity = forwardVelocity + rightVelocity * driftPower;
    }

    void SlowDownToMaxSpeed()
    {
        Vector2 slowDownForce = -transform.up * accelerationPower * 2f;
        body.AddForce(slowDownForce, ForceMode2D.Force);
    }
}
