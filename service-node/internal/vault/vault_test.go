package vault

import (
	"testing"
)

func TestNew(t *testing.T) {
	// Test with correct key length
	key := make([]byte, 32)
	v, err := New(key)
	if err != nil {
		t.Fatalf("failed to create vault: %v", err)
	}
	if v == nil {
		t.Fatal("expected non-nil vault")
	}

	// Test with incorrect key length
	shortKey := make([]byte, 16)
	_, err = New(shortKey)
	if err != ErrInvalidKey {
		t.Errorf("expected ErrInvalidKey, got %v", err)
	}
}

func TestNewFromString(t *testing.T) {
	// Test with short key (should be padded)
	v, err := NewFromString("short-key")
	if err != nil {
		t.Fatalf("failed to create vault from short string: %v", err)
	}
	if v == nil {
		t.Fatal("expected non-nil vault")
	}

	// Test with long key (should be truncated)
	v, err = NewFromString("this-is-a-very-long-key-that-exceeds-32-bytes")
	if err != nil {
		t.Fatalf("failed to create vault from long string: %v", err)
	}
	if v == nil {
		t.Fatal("expected non-nil vault")
	}

	// Test with exact length key
	v, err = NewFromString("exactly-32-bytes-long-key-here!")
	if err != nil {
		t.Fatalf("failed to create vault from exact string: %v", err)
	}
	if v == nil {
		t.Fatal("expected non-nil vault")
	}
}

func TestEncryptDecrypt(t *testing.T) {
	v, err := NewFromString("test-encryption-key-for-vault!!")
	if err != nil {
		t.Fatalf("failed to create vault: %v", err)
	}

	original := &CredentialData{
		Password:   "secret-password",
		PrivateKey: "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
		Passphrase: "key-passphrase",
		Token:      "api-token-12345",
		Extra: map[string]string{
			"custom_field": "custom_value",
		},
	}

	// Encrypt
	ciphertext, nonce, err := v.Encrypt(original)
	if err != nil {
		t.Fatalf("failed to encrypt: %v", err)
	}

	if len(ciphertext) == 0 {
		t.Error("expected non-empty ciphertext")
	}

	if len(nonce) == 0 {
		t.Error("expected non-empty nonce")
	}

	// Decrypt
	decrypted, err := v.Decrypt(ciphertext, nonce)
	if err != nil {
		t.Fatalf("failed to decrypt: %v", err)
	}

	// Verify
	if decrypted.Password != original.Password {
		t.Errorf("expected password '%s', got '%s'", original.Password, decrypted.Password)
	}

	if decrypted.PrivateKey != original.PrivateKey {
		t.Errorf("expected private key '%s', got '%s'", original.PrivateKey, decrypted.PrivateKey)
	}

	if decrypted.Passphrase != original.Passphrase {
		t.Errorf("expected passphrase '%s', got '%s'", original.Passphrase, decrypted.Passphrase)
	}

	if decrypted.Token != original.Token {
		t.Errorf("expected token '%s', got '%s'", original.Token, decrypted.Token)
	}

	if decrypted.Extra["custom_field"] != original.Extra["custom_field"] {
		t.Errorf("expected extra field '%s', got '%s'", original.Extra["custom_field"], decrypted.Extra["custom_field"])
	}
}

func TestEncryptDecryptString(t *testing.T) {
	v, err := NewFromString("test-encryption-key-for-vault!!")
	if err != nil {
		t.Fatalf("failed to create vault: %v", err)
	}

	original := "my-secret-string"

	// Encrypt
	ciphertext, nonce, err := v.EncryptString(original)
	if err != nil {
		t.Fatalf("failed to encrypt string: %v", err)
	}

	// Decrypt
	decrypted, err := v.DecryptString(ciphertext, nonce)
	if err != nil {
		t.Fatalf("failed to decrypt string: %v", err)
	}

	if decrypted != original {
		t.Errorf("expected '%s', got '%s'", original, decrypted)
	}
}

func TestDecryptWithWrongKey(t *testing.T) {
	v1, _ := NewFromString("key-one-for-encryption-32bytes!")
	v2, _ := NewFromString("key-two-for-decryption-32bytes!")

	original := &CredentialData{Password: "secret"}

	// Encrypt with v1
	ciphertext, nonce, err := v1.Encrypt(original)
	if err != nil {
		t.Fatalf("failed to encrypt: %v", err)
	}

	// Try to decrypt with v2 (should fail)
	_, err = v2.Decrypt(ciphertext, nonce)
	if err != ErrDecryptFailed {
		t.Errorf("expected ErrDecryptFailed, got %v", err)
	}
}

func TestEncryptProducesDifferentOutput(t *testing.T) {
	v, err := NewFromString("test-encryption-key-for-vault!!")
	if err != nil {
		t.Fatalf("failed to create vault: %v", err)
	}

	data := &CredentialData{Password: "same-password"}

	// Encrypt twice
	ciphertext1, nonce1, _ := v.Encrypt(data)
	ciphertext2, nonce2, _ := v.Encrypt(data)

	// Nonces should be different
	if string(nonce1) == string(nonce2) {
		t.Error("nonces should be different")
	}

	// Ciphertexts should be different (due to different nonces)
	if string(ciphertext1) == string(ciphertext2) {
		t.Error("ciphertexts should be different")
	}
}
