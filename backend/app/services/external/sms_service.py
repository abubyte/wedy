import httpx
import logging
import asyncio
from typing import Optional

from app.core.config import settings
from app.core.exceptions import SMSError

logger = logging.getLogger(__name__)


class SMSService:
    """SMS service for sending OTP messages via eskiz.uz."""
    
    def __init__(self):
        self.base_url = settings.ESKIZ_BASE_URL
        self._token: Optional[str] = None
    
    async def _get_auth_token(self) -> str:
        """
        Get authentication token from eskiz.uz API.
        
        Returns:
            str: Authentication token
            
        Raises:
            SMSError: If authentication fails
        """
        if self._token:
            return self._token
        
        auth_url = f"{self.base_url}/auth/login"
        auth_data = {
            "email": settings.ESKIZ_EMAIL,
            "password": settings.ESKIZ_PASSWORD
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(auth_url, json=auth_data)
                
                if response.status_code == 200:
                    data = response.json()
                    self._token = data.get("data", {}).get("token")
                    
                    if not self._token:
                        raise SMSError("No token received from SMS service")
                    
                    return self._token
                else:
                    raise SMSError(f"SMS authentication failed: {response.status_code}")
        
        except httpx.RequestError as e:
            logger.error(f"SMS service request error: {e}")
            raise SMSError("Failed to connect to SMS service")
        except Exception as e:
            logger.error(f"SMS authentication error: {e}")
            raise SMSError("SMS service authentication failed")
    
    async def send_otp(self, phone_number: str, otp_code: str) -> bool:
        """
        Send OTP SMS to phone number.
        
        Args:
            phone_number: 9-digit phone number (Uzbekistan format)
            otp_code: OTP code to send
            
        Returns:
            bool: True if SMS sent successfully
            
        Raises:
            SMSError: If SMS sending fails
        """
        # For development/testing, just log the OTP
        if settings.DEBUG:
            logger.info(f"OTP for {phone_number}: {otp_code}")
            return True
        
        # Retry transient provider errors a few times before giving up
        MAX_RETRIES = 3
        RETRY_DELAY = 2  # seconds

        try:
            # Get authentication token
            token = await self._get_auth_token()

            # Prepare SMS data
            sms_url = f"{self.base_url}/message/sms/send"

            # Add country code for Uzbekistan
            full_phone = f"998{phone_number}"

            sms_data = {
                "mobile_phone": full_phone,
                "message": f"Wedy mobil ilovasi uchun tasdiqlash kodi: {otp_code}", # TODO: REMOVE 'MOBIL'
                "from": "4546"
            }

            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }

            attempt = 0
            while attempt < MAX_RETRIES:
                attempt += 1
                async with httpx.AsyncClient() as client:
                    response = await client.post(
                        sms_url, 
                        json=sms_data, 
                        headers=headers,
                        timeout=30.0
                    )

                # Success path
                if response.status_code == 200:
                    data = response.json()
                    if data.get("status") == "success":
                        logger.info(f"OTP sent successfully to {phone_number}")
                        return True

                    # Provider returned a non-success status; check for transient message
                    error_msg = data.get("message", "Unknown error")
                    if "waiting for sms provider" in error_msg.lower() or "waiting" in error_msg.lower():
                        logger.warning(f"Transient SMS provider response (attempt {attempt}/{MAX_RETRIES}): {error_msg}")
                        if attempt < MAX_RETRIES:
                            await asyncio.sleep(RETRY_DELAY)
                            continue
                        else:
                            logger.error(f"SMS sending failed after retries: {error_msg}")
                            raise SMSError(f"Failed to send SMS after retries: {error_msg}")
                    else:
                        logger.error(f"SMS sending failed: {error_msg}")
                        raise SMSError(f"Failed to send SMS: {error_msg}")

                elif response.status_code == 401:
                    # Token expired, clear it and retry once (reset attempt counter)
                    self._token = None
                    logger.warning("SMS token expired, refreshing token and retrying...")
                    token = await self._get_auth_token()
                    headers["Authorization"] = f"Bearer {token}"
                    # do not increment attempt here; continue to retry with new token
                    continue

                else:
                    logger.error(f"SMS API error: {response.status_code} - {response.text}")
                    raise SMSError(f"SMS service error: {response.status_code}")

            # If loop exits without returning, raise a generic error
            raise SMSError("SMS service temporarily unavailable")

        except httpx.RequestError as e:
            logger.error(f"SMS service request error: {e}")
            raise SMSError("Failed to connect to SMS service")
        except SMSError:
            # Re-raise SMS errors
            raise
        except Exception as e:
            logger.error(f"Unexpected SMS error: {e}")
            raise SMSError("SMS service temporarily unavailable")
    
    async def send_notification(self, phone_number: str, message: str) -> bool:
        """
        Send notification SMS to phone number.
        
        Args:
            phone_number: 9-digit phone number (Uzbekistan format)
            message: Message to send
            
        Returns:
            bool: True if SMS sent successfully
            
        Raises:
            SMSError: If SMS sending fails
        """
        # For development/testing, just log the message
        if settings.DEBUG:
            logger.info(f"SMS to {phone_number}: {message}")
            return True
        
        # Retry transient provider errors a few times before giving up
        MAX_RETRIES = 3
        RETRY_DELAY = 2  # seconds

        try:
            # Get authentication token
            token = await self._get_auth_token()

            # Prepare SMS data
            sms_url = f"{self.base_url}/message/sms/send"

            # Add country code for Uzbekistan
            full_phone = f"998{phone_number}"

            sms_data = {
                "mobile_phone": full_phone,
                "message": message,
                "from": "4546"
            }

            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }

            attempt = 0
            while attempt < MAX_RETRIES:
                attempt += 1
                async with httpx.AsyncClient() as client:
                    response = await client.post(
                        sms_url, 
                        json=sms_data, 
                        headers=headers,
                        timeout=30.0
                    )

                if response.status_code == 200:
                    data = response.json()
                    if data.get("status") == "success":
                        logger.info(f"Notification sent successfully to {phone_number}")
                        return True

                    error_msg = data.get("message", "Unknown error")
                    if "waiting for sms provider" in error_msg.lower() or "waiting" in error_msg.lower():
                        logger.warning(f"Transient SMS provider response (attempt {attempt}/{MAX_RETRIES}): {error_msg}")
                        if attempt < MAX_RETRIES:
                            await asyncio.sleep(RETRY_DELAY)
                            continue
                        else:
                            logger.error(f"Notification failed after retries: {error_msg}")
                            raise SMSError(f"Failed to send SMS after retries: {error_msg}")
                    else:
                        logger.error(f"SMS sending failed: {error_msg}")
                        raise SMSError(f"Failed to send SMS: {error_msg}")

                elif response.status_code == 401:
                    # Token expired, clear it and retry once
                    self._token = None
                    logger.warning("SMS token expired, refreshing token and retrying...")
                    token = await self._get_auth_token()
                    headers["Authorization"] = f"Bearer {token}"
                    continue

                else:
                    logger.error(f"SMS API error: {response.status_code} - {response.text}")
                    raise SMSError(f"SMS service error: {response.status_code}")

            raise SMSError("SMS service temporarily unavailable")

        except httpx.RequestError as e:
            logger.error(f"SMS service request error: {e}")
            raise SMSError("Failed to connect to SMS service")
        except SMSError:
            # Re-raise SMS errors
            raise
        except Exception as e:
            logger.error(f"Unexpected SMS error: {e}")
            raise SMSError("SMS service temporarily unavailable")
        
# import httpx #FIX_SMS_SERVICE
# import logging
# from typing import Optional

# from app.core.config import settings
# from app.core.exceptions import SMSError

# logger = logging.getLogger(__name__)


# class SMSService:
#     """SMS service for sending OTP messages via eskiz.uz."""
    
#     def __init__(self):
#         self.base_url = settings.SMS_BASE_URL
#         self.api_key = settings.SMS_API_KEY
#         self._token: Optional[str] = None
    
#     async def _get_auth_token(self) -> str:
#         """
#         Get authentication token from eskiz.uz API.
        
#         Returns:
#             str: Authentication token
            
#         Raises:
#             SMSError: If authentication fails
#         """
#         if self._token:
#             return self._token
        
#         auth_url = f"{self.base_url}/auth/login"
#         auth_data = {
#             "email": "your_email@example.com",  # Replace with actual email
#             "password": "your_password"  # Replace with actual password
#         }
        
#         try:
#             async with httpx.AsyncClient() as client:
#                 response = await client.post(auth_url, json=auth_data)
                
#                 if response.status_code == 200:
#                     data = response.json()
#                     self._token = data.get("data", {}).get("token")
                    
#                     if not self._token:
#                         raise SMSError("No token received from SMS service")
                    
#                     return self._token
#                 else:
#                     raise SMSError(f"SMS authentication failed: {response.status_code}")
        
#         except httpx.RequestError as e:
#             logger.error(f"SMS service request error: {e}")
#             raise SMSError("Failed to connect to SMS service")
#         except Exception as e:
#             logger.error(f"SMS authentication error: {e}")
#             raise SMSError("SMS service authentication failed")
    
#     async def send_otp(self, phone_number: str, otp_code: str) -> bool:
#         """
#         Send OTP SMS to phone number.
        
#         Args:
#             phone_number: 9-digit phone number (Uzbekistan format)
#             otp_code: OTP code to send
            
#         Returns:
#             bool: True if SMS sent successfully
            
#         Raises:
#             SMSError: If SMS sending fails
#         """
#         # For development/testing, just log the OTP
#         if settings.DEBUG:
#             logger.info(f"OTP for {phone_number}: {otp_code}")
#             return True
        
#         try:
#             # Get authentication token
#             token = await self._get_auth_token()
            
#             # Prepare SMS data
#             sms_url = f"{self.base_url}/message/sms/send"
            
#             # Add country code for Uzbekistan
#             full_phone = f"998{phone_number}"
            
#             sms_data = {
#                 "mobile_phone": full_phone,
#                 "message": f"Wedy verification code: {otp_code}. Do not share this code.",
#                 "from": "4546"
#             }
            
#             headers = {
#                 "Authorization": f"Bearer {token}",
#                 "Content-Type": "application/json"
#             }
            
#             async with httpx.AsyncClient() as client:
#                 response = await client.post(
#                     sms_url, 
#                     json=sms_data, 
#                     headers=headers,
#                     timeout=30.0
#                 )
                
#                 if response.status_code == 200:
#                     data = response.json()
                    
#                     # Check if SMS was sent successfully
#                     if data.get("status") == "success":
#                         logger.info(f"OTP sent successfully to {phone_number}")
#                         return True
#                     else:
#                         error_msg = data.get("message", "Unknown error")
#                         logger.error(f"SMS sending failed: {error_msg}")
#                         raise SMSError(f"Failed to send SMS: {error_msg}")
                
#                 elif response.status_code == 401:
#                     # Token expired, clear it and retry once
#                     self._token = None
#                     logger.warning("SMS token expired, retrying...")
#                     return await self.send_otp(phone_number, otp_code)
                
#                 else:
#                     logger.error(f"SMS API error: {response.status_code} - {response.text}")
#                     raise SMSError(f"SMS service error: {response.status_code}")
        
#         except httpx.RequestError as e:
#             logger.error(f"SMS service request error: {e}")
#             raise SMSError("Failed to connect to SMS service")
#         except SMSError:
#             # Re-raise SMS errors
#             raise
#         except Exception as e:
#             logger.error(f"Unexpected SMS error: {e}")
#             raise SMSError("SMS service temporarily unavailable")
    
#     async def send_notification(self, phone_number: str, message: str) -> bool:
#         """
#         Send notification SMS to phone number.
        
#         Args:
#             phone_number: 9-digit phone number (Uzbekistan format)
#             message: Message to send
            
#         Returns:
#             bool: True if SMS sent successfully
            
#         Raises:
#             SMSError: If SMS sending fails
#         """
#         # For development/testing, just log the message
#         if settings.DEBUG:
#             logger.info(f"SMS to {phone_number}: {message}")
#             return True
        
#         try:
#             # Get authentication token
#             token = await self._get_auth_token()
            
#             # Prepare SMS data
#             sms_url = f"{self.base_url}/message/sms/send"
            
#             # Add country code for Uzbekistan
#             full_phone = f"998{phone_number}"
            
#             sms_data = {
#                 "mobile_phone": full_phone,
#                 "message": message,
#                 "from": "4546"  # Default sender ID
#             }
            
#             headers = {
#                 "Authorization": f"Bearer {token}",
#                 "Content-Type": "application/json"
#             }
            
#             async with httpx.AsyncClient() as client:
#                 response = await client.post(
#                     sms_url, 
#                     json=sms_data, 
#                     headers=headers,
#                     timeout=30.0
#                 )
                
#                 if response.status_code == 200:
#                     data = response.json()
                    
#                     if data.get("status") == "success":
#                         logger.info(f"Notification sent successfully to {phone_number}")
#                         return True
#                     else:
#                         error_msg = data.get("message", "Unknown error")
#                         logger.error(f"SMS sending failed: {error_msg}")
#                         raise SMSError(f"Failed to send SMS: {error_msg}")
                
#                 elif response.status_code == 401:
#                     # Token expired, clear it and retry once
#                     self._token = None
#                     logger.warning("SMS token expired, retrying...")
#                     return await self.send_notification(phone_number, message)
                
#                 else:
#                     logger.error(f"SMS API error: {response.status_code} - {response.text}")
#                     raise SMSError(f"SMS service error: {response.status_code}")
        
#         except httpx.RequestError as e:
#             logger.error(f"SMS service request error: {e}")
#             raise SMSError("Failed to connect to SMS service")
#         except SMSError:
#             # Re-raise SMS errors
#             raise
#         except Exception as e:
#             logger.error(f"Unexpected SMS error: {e}")
#             raise SMSError("SMS service temporarily unavailable")