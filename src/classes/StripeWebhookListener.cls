global virtual class StripeWebhookListener {
	public StripeEvent event;

	global void handlePost() {
		RestResponse response = RestContext.response;
		response.addHeader('Content-type','application/json');
		System.debug(System.LoggingLevel.INFO, '\n**** '+RestContext.request.requestBody.toString());

		try {
			event = StripeEvent.parse(RestContext.request.requestBody.toString());
		} catch (StripeEvent.UnknownWebhookException e) {
			// gracefully decline
			response.responseBody = Blob.valueOf(JSON.serializePretty(e));
			response.statusCode = 200;
			return;
		} catch (System.Exception e) {
			response.responseBody = Blob.valueOf(JSON.serializePretty(e));
			response.statusCode = 500;
			return;
		}

		// prevent tests from hitting production
		if (event.livemode == false && StripeAPI.isTest == false) {
			System.debug(System.LoggingLevel.INFO, '\n**** Bailing out'); 
			return;
		}
		
		System.debug(System.LoggingLevel.INFO, '\n**** Event Type in Listener: '+event.stripeType); 
		
		try {
			//
			// Invoice Webhooks
			//
			if (event.stripeType == 'invoice.created') {
				handle_InvoiceCreated(event.stripeData.StripeInvoice);

			} else if (event.stripeType == 'invoice.payment_succeeded') {
				handle_InvoicePaymentSucceeded(event.stripeData.StripeInvoice);

			} else if (event.stripeType == 'invoice.payment_failed') {
				handle_InvoicePaymentFailed(event.stripeData.StripeInvoice);

			}

			//
			// Subscription webhooks
			//
			else if (event.stripeType == 'customer.subscription.deleted') {
				handle_CustomerSubscriptionDeleted(event.stripeData.StripeSubscription);
			}

			//
			// Customer webhooks
			//
			else if (event.stripeType == 'customer.updated') {
				handle_CustomerUpdated(event.stripeData.StripeCustomer);
			}

			//
			// Charge webhooks
			//
			else if (event.stripeType == 'charge.succeeded') {
				handle_ChargeSucceeded(event.stripeData.StripeCharge);

			} else if (event.stripeType == 'charge.failed') {
				handle_ChargeFailed(event.stripeData.StripeCharge);

			} else if (event.stripeType == 'charge.refunded') {
				handle_ChargeRefunded(event.stripeData.StripeCharge);

			} else if (event.stripeType == 'ping') {
				// Do nothing - will respond with a 200

			} else {
				response.statusCode = 400;
				response.responseBody = Blob.valueOf('{success:false, event:"'+event.stripeType+'",message:"Unhandled event"}');
				return;
			}
		} catch (StripeException e) {
			response.responseBody = Blob.valueOf(JSON.serializePretty(e));
			System.debug(System.LoggingLevel.INFO, '\n**** Listener Handler Error: '+response.responseBody.toString()); 
			response.statusCode = 406;
			return;
		}

		// OK
		response.statusCode = 200;
		response.responseBody = Blob.valueOf('{success:true, event:"'+event.stripeType+'"}');
	}
	
	// Handle the invoice.created webhook
	global virtual void handle_InvoiceCreated(StripeInvoice invoice) {
		throw new StripeEvent.UnknownWebhookException('Not implemented');
	}
	
	// Handle the invoice.payment_succeeded webhook
	global virtual void handle_InvoicePaymentSucceeded(StripeInvoice invoice) {
		throw new StripeEvent.UnknownWebhookException('Not implemented');
	}
	
	// Handle the invoice.payment_failed webhook
	global virtual void handle_InvoicePaymentFailed(StripeInvoice invoice) {
		throw new StripeEvent.UnknownWebhookException('Not implemented');
	}

	// Handle the customer.subscription.deleted webhook
	global virtual void handle_CustomerSubscriptionDeleted(StripeSubscription subscription) {
		throw new StripeEvent.UnknownWebhookException('Not implemented');
	}
	
	// Handle the customer.updated webhook
	global virtual void handle_CustomerUpdated(StripeCustomer customer) {
		throw new StripeEvent.UnknownWebhookException('Not implemented');
	}
	
	// Handle the charge.succeeded webhook
	global virtual void handle_ChargeSucceeded(StripeCharge charge) {
		handle_ChargeSucceeded(charge, true);
	}

	// Handle the charge.succeeded webhook
	global virtual void handle_ChargeSucceeded(StripeCharge charge, Boolean allowDelayedProcessing) {
		throw new StripeEvent.UnknownWebhookException('Not implemented');
	}

	// Handle the charge.failed webhook
	global virtual void handle_ChargeFailed(StripeCharge charge) {
		throw new StripeEvent.UnknownWebhookException('Not implemented');
	}

	// Handle the charge.refunded webhook
	global virtual void handle_ChargeRefunded(StripeCharge charge) {
		throw new StripeEvent.UnknownWebhookException('Not implemented');
	}
	
	// Utility logging method
	public void createWebhookTask(String subject, Id whatId) {
		DateTime timestamp = DateTime.now();
		Task task = new Task(
			Description = timestamp.formatLong() + '\n\n' + RestContext.request.requestBody.toString(),
			Status = 'Completed',
			Subject = subject,
			Type = 'Stripe Webhook',
			WhatId = whatId
		);
		
		try {
			insert task;
		} catch (Exception e) {
			System.debug(System.LoggingLevel.INFO, '\n**** Error Inserting Task:'+e); 
		}
	}

}