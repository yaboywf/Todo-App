const crypto = require('crypto');
const fs = require('fs');

function createIv() {
    return crypto.randomBytes(16);
}

/**
    * Used to encrypt data
    * @param {string} text - The plain text data to be encrypted
    * @param {Buffer} key - The encryption / decryption key
    * @param {Buffer} iv - The initialization vector (IV) used for decryption
    * @returns {string} - The decrypted plaintext as a UTF-8 string.
*/
function encrypt(text, key, iv) {
    const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return encrypted
}

/**
    * Used to decrypt data
    * @param {Buffer | string} encryptedData - The data to be decrypted
    * @param {Buffer} key - The encryption / decryption key
    * @param {Buffer} iv - The initialization vector (IV) used for decryption
    * @returns {string} - The decrypted plaintext as a UTF-8 string.
*/
function decrypt(encryptedData, key, iv) {
    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let decrypted = decipher.update(encryptedData, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted
}

/**
 * Derive a key from the password and salt using PBKDF2
 * @param {string} password - The password used to derive the key
 * @param {string} salt - A salt value used for PBKDF2
 * @returns {Buffer} - The derived 32-byte key
 */
function getKey(password, salt) {
    return crypto.pbkdf2Sync(password, salt, 100000, 32, 'sha256');  // 100000 iterations, 32-byte key, 'sha256' hash
}

/**
 * Encrypts an image from a stream.
 * @param {Buffer} imageBuffer - Buffer from image file.
 * @param {Buffer} key - The encryption key (32 bytes for AES-256).
 * @param {Buffer} iv - The initialization vector (16 bytes for AES).
 * @returns {ReadableStream} - A stream of encrypted data.
 */
function encryptImage(imageBuffer, key, iv) {
    const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
    let encrypted = cipher.update(imageBuffer);
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    return encrypted
}

/**
 * Decrypt the encrypted image data from Firebird
 * @param {Buffer} encryptedData - The encrypted image data from the database
 * @param {Buffer} key - The AES encryption key
 * @param {Buffer} iv - The initialization vector used for encryption
 * @returns {Buffer} - The decrypted image data
 */
function decryptImage(encryptedData, key, iv) {
    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let decrypted = decipher.update(encryptedData);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted;
}

module.exports = { encrypt, decrypt, getKey, createIv, encryptImage, decryptImage }