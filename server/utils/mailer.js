import nodemailer from 'nodemailer';
import dotenv from 'dotenv';
dotenv.config();

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

export async function sendOtpMail(to, otp) {
  const info = await transporter.sendMail({
    from: `"TidTung" <${process.env.EMAIL_USER}>`,
    to,
    subject: 'Your TidTung Login OTP',
    text: `Your OTP code is: ${otp}`,
    html: `
      <h2>Your OTP Code</h2>
      <p style="font-size: 20px; font-weight: bold;">${otp}</p>
      <p>This code expires in 5 minutes.</p>
    `,
  });

  console.log('📧 Sent OTP email ID:', info.messageId);
}
