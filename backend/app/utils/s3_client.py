import boto3
from botocore.exceptions import ClientError
from typing import Optional, Tuple
import uuid
import mimetypes
from datetime import datetime, timedelta

from app.core.config import settings


class S3ImageManager:
    """AWS S3 client for image upload and management."""
    
    def __init__(self):
        self.s3_client = boto3.client(
            's3',
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_REGION
        )
        self.bucket_name = settings.AWS_BUCKET_NAME
    
    def generate_presigned_upload_url(
        self,
        file_name: str,
        content_type: str,
        image_type: str,
        related_id: str,
        expires_in: int = 3600
    ) -> Tuple[str, str]:
        """
        Generate presigned URL for image upload.
        
        Args:
            file_name: Original file name
            content_type: MIME type of the file
            image_type: Type of image (service_image, merchant_gallery, etc.)
            related_id: ID of related entity
            expires_in: URL expiration time in seconds
            
        Returns:
            Tuple of (s3_key, presigned_url)
            
        Raises:
            ValueError: If content type is not allowed
        """
        # Validate content type
        allowed_types = ['image/jpeg', 'image/png', 'image/webp']
        if content_type not in allowed_types:
            raise ValueError(f"Content type {content_type} not allowed")
        
        # Generate unique S3 key
        file_extension = mimetypes.guess_extension(content_type) or '.jpg'
        unique_id = str(uuid.uuid4())
        s3_key = f"{image_type}/{related_id}/{unique_id}{file_extension}"
        
        try:
            presigned_url = self.s3_client.generate_presigned_url(
                'put_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': s3_key,
                    'ContentType': content_type,
                    'ContentLength': 5 * 1024 * 1024  # Max 5MB
                },
                ExpiresIn=expires_in
            )
            
            s3_url = f"https://{self.bucket_name}.s3.{settings.AWS_REGION}.amazonaws.com/{s3_key}"
            
            return s3_url, presigned_url
            
        except ClientError as e:
            raise Exception(f"Failed to generate presigned URL: {str(e)}")
    
    def delete_image(self, s3_url: str) -> bool:
        """
        Delete image from S3.
        
        Args:
            s3_url: Full S3 URL of the image
            
        Returns:
            True if deleted successfully, False otherwise
        """
        try:
            # Extract S3 key from URL
            s3_key = self._extract_key_from_url(s3_url)
            if not s3_key:
                return False
            
            self.s3_client.delete_object(
                Bucket=self.bucket_name,
                Key=s3_key
            )
            return True
            
        except ClientError:
            return False
    
    def get_image_info(self, s3_url: str) -> Optional[dict]:
        """
        Get image metadata from S3.
        
        Args:
            s3_url: Full S3 URL of the image
            
        Returns:
            Dictionary with image metadata or None if not found
        """
        try:
            s3_key = self._extract_key_from_url(s3_url)
            if not s3_key:
                return None
            
            response = self.s3_client.head_object(
                Bucket=self.bucket_name,
                Key=s3_key
            )
            
            return {
                'content_length': response.get('ContentLength'),
                'content_type': response.get('ContentType'),
                'last_modified': response.get('LastModified'),
                'etag': response.get('ETag')
            }
            
        except ClientError:
            return None
    
    def _extract_key_from_url(self, s3_url: str) -> Optional[str]:
        """
        Extract S3 key from full URL.
        
        Args:
            s3_url: Full S3 URL
            
        Returns:
            S3 key or None if invalid URL
        """
        try:
            # Expected format: https://bucket.s3.region.amazonaws.com/key
            if not s3_url.startswith('https://'):
                return None
            
            # Remove protocol and domain
            parts = s3_url.replace('https://', '').split('/', 1)
            if len(parts) < 2:
                return None
            
            return parts[1]  # This is the S3 key
            
        except Exception:
            return None
    
    def validate_image_constraints(self, content_type: str, content_length: int) -> None:
        """
        Validate image constraints.
        
        Args:
            content_type: MIME type of the image
            content_length: Size of the image in bytes
            
        Raises:
            ValueError: If constraints are violated
        """
        # Check content type
        allowed_types = ['image/jpeg', 'image/png', 'image/webp']
        if content_type not in allowed_types:
            raise ValueError(f"Content type {content_type} not allowed. Allowed types: {allowed_types}")
        
        # Check file size (5MB max)
        max_size = 5 * 1024 * 1024  # 5MB
        if content_length > max_size:
            raise ValueError(f"File size {content_length} exceeds maximum of {max_size} bytes")
        
        # Check minimum size (1KB)
        min_size = 1024  # 1KB
        if content_length < min_size:
            raise ValueError(f"File size {content_length} is below minimum of {min_size} bytes")


# Global instance
s3_image_manager = S3ImageManager()