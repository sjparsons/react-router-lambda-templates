# Welcome to React Router on AWS Lambda

A modern, production-ready template for building full-stack React applications using React Router and deploying to Amazon Web Services (AWS) using CloudFront, Lambda and S3.

## Features

- 🚀 Server-side rendering
- ⚡️ Hot Module Replacement (HMR)
- 📦 Asset bundling and optimization
- 🔄 Data loading and mutations
- 🔒 TypeScript by default
- 🎉 TailwindCSS for styling
- 📖 [React Router docs](https://reactrouter.com/)
- 🌎 Deploy on AWS using Cloudfront, Lambda and S3

## Getting Started

### Installation

Install the dependencies:

```bash
npm install
```

### Development

Start the development server with HMR:

```bash
npm run dev
```

Your application will be available at `http://localhost:5173`.

## Building for Production

Create a production build:

```bash
npm run build
```

## Deployment with AWS Lambda

This package includes a basic setup for deploying this react router app to a AWS Cloudfront Distribution backed by a AWS Lambda URL for server-side rendering and AWS S3 bucket to serve the static assets. Note Lambda and CloudFront are in the "always free" free-tier of AWS (as of writing) so basic usage should not cost much. AWS S3 will cost money after your first 12 months, but turns out to be fairly affordable. Before deploy you may wish to confirm current status of the [AWS Free Tier](https://aws.amazon.com/free/) and whether you will incur costs.

To get started, you'll first want to make sure you do the following to get setup:

1. [Install terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform)
2. [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
3. Configure your AWS CLI for the account you wish to deploy to.

For more details to configure Terraform and AWS see the [AWS and terraform prerequisites](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build#prerequisites).

### Deploying

To deploy simply run the following npm script:

```
npm run deploy
```

You will be presented with the terraform changes that will be applied. After reviewing the terraform changes, type `yes` and then hit enter to complete deploying your application. Once complete, the output will include a `cloudfront_distribution_link` that you can visit. For example:

```
Outputs:

assets_bucket_name = "react-router-app-assets-my-folder"
cloudfront_distribution_link = "https://abc.cloudfront.net"
lambda_function_name = "react-router-app-my-folder"
```

Note: the first deploy can take a few minutes since an AWS CloudFront distribution has to be created.

### Next steps with terraform

If you want to dive into details you can go to the `terraform/` folder and view the [README](./terraform/README.md) there.

## Styling

This template comes with [Tailwind CSS](https://tailwindcss.com/) already configured for a simple default starting experience. You can use whatever CSS framework you prefer.

---

Built with ❤️ using React Router.
