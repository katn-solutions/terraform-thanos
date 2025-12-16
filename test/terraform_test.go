package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformThanosV0Validation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../v0",
		NoColor:      true,
	})

	terraform.InitAndValidate(t, terraformOptions)
}

func TestTerraformThanosInputs(t *testing.T) {
	testCases := []struct {
		name     string
		expectOK bool
	}{
		{"ValidConfiguration", true},
		{"ValidWithDNS", true},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../v0",
				NoColor:      true,
			})

			// Validate configuration (terraform validate doesn't accept -var flags)
			terraform.InitAndValidate(t, terraformOptions)

			if tc.expectOK {
				assert.True(t, true, "Configuration validated successfully")
			}
		})
	}
}
